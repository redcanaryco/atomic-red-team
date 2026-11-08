#Requires -Version 5.1
<#
Creates two disposable, disabled AD users and migrates the source SID to the
destination through DSInternals RPC. The RPC operation DELETES the source user.
No existing user DN or arbitrary SID can be supplied to this script.
#>
[CmdletBinding()]
param(
    [ValidateSet('Run', 'Cleanup')][string]$Mode = 'Run',
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Server,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$StatePath,
    [System.Management.Automation.PSCredential]$Credential
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$StatePath = [IO.Path]::GetFullPath($StatePath)

function Save-State {
    $json = $script:state | ConvertTo-Json -Depth 5
    # Keep recovery information if execution or verification fails.
    [IO.File]::WriteAllText($StatePath, $json, [Text.UTF8Encoding]::new($false))
}

function Get-OptionalObject([string]$DN) {
    try {
        Get-ADObject -Identity $DN -Properties Description, objectGUID @script:ad
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        return $null
    }
}

function Assert-OwnedObject($Object, [string]$ExpectedClass, [string]$ExpectedGuid) {
    if ($Object.ObjectClass -ne $ExpectedClass -or $Object.Description -cne $script:state.Marker) {
        throw "Ownership check failed for $($Object.DistinguishedName). No deletion performed."
    }
    if ($ExpectedGuid -and $Object.ObjectGUID.ToString() -ne $ExpectedGuid) {
        throw "Object GUID changed for $($Object.DistinguishedName). No deletion performed."
    }
}

if ($Mode -eq 'Cleanup' -and -not (Test-Path -LiteralPath $StatePath)) {
    Write-Output 'No state file exists; nothing to clean up.'
    return
}
if ($Mode -eq 'Run' -and (Test-Path -LiteralPath $StatePath)) {
    throw 'State file already exists. Complete cleanup or choose another state path.'
}

# Validate manifest structure BEFORE using its DNs for any directory operation.
if ($Mode -eq 'Cleanup') {
    $script:state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    if ($state.Schema -ne 1 -or $state.Server -ine $Server -or
        $state.RunId -notmatch '^[a-f0-9]{32}$' -or
        $state.DomainDN -notmatch '^DC=[^,=]+(,DC=[^,=]+)*$') {
        throw 'Invalid state file or server mismatch.'
    }
    $expectedOU = "OU=ART-T1134-005-$($state.RunId),$($state.DomainDN)"
    $suffix = $state.RunId.Substring(0, 12)
    if ($state.OuDN -cne $expectedOU -or
        $state.SourceDN -cne "CN=ARTSRC-$suffix,$expectedOU" -or
        $state.DestinationDN -cne "CN=ARTDST-$suffix,$expectedOU" -or
        $state.Marker -cne "AtomicRedTeam:T1134.005:$($state.RunId)") {
        throw 'Manifest contains unexpected object paths or marker.'
    }
}

Import-Module ActiveDirectory -ErrorAction Stop
$script:ad = @{ Server = $Server; ErrorAction = 'Stop' }
if ($Credential) { $script:ad.Credential = $Credential }

if ($Mode -eq 'Cleanup') {
    $ou = Get-OptionalObject $state.OuDN
    if ($ou) {
        Assert-OwnedObject $ou 'organizationalUnit' $state.OuGuid
        foreach ($entry in @(@($state.SourceGuid, $state.SourceDN), @($state.DestinationGuid, $state.DestinationDN))) {
            if ($entry[0]) {
                $recorded = Get-OptionalObject $entry[0]
                if ($recorded -and $recorded.DistinguishedName -ine $entry[1]) {
                    throw 'A recorded test account was moved. Manual review required; state retained.'
                }
            }
        }
        $children = @(Get-ADObject -SearchBase $state.OuDN -SearchScope OneLevel -Filter * -Properties Description @ad)
        foreach ($child in $children) {
            if ($child.DistinguishedName -ieq $state.SourceDN) {
                Assert-OwnedObject $child 'user' $state.SourceGuid
            }
            elseif ($child.DistinguishedName -ieq $state.DestinationDN) {
                Assert-OwnedObject $child 'user' $state.DestinationGuid
            }
            else { throw 'Unexpected object in test OU. Cleanup stopped without deleting any children.' }
        }
        foreach ($child in $children) {
            # Delete by GUID, not a name that could have been reused.
            Remove-ADUser -Identity $child.ObjectGUID -Confirm:$false @ad
        }
        if (@(Get-ADObject -SearchBase $state.OuDN -SearchScope OneLevel -Filter * @ad).Count -ne 0) {
            throw 'Test OU is not empty. Refusing to remove it.'
        }
        Set-ADOrganizationalUnit -Identity $ou.ObjectGUID -ProtectedFromAccidentalDeletion $false @ad
        Remove-ADOrganizationalUnit -Identity $ou.ObjectGUID -Confirm:$false @ad
    }
    else {
        # A missing OU might mean that an operator moved it. Do not silently
        # discard the recovery record while its recorded objects still exist.
        foreach ($guid in @($state.OuGuid, $state.SourceGuid, $state.DestinationGuid)) {
            if ($guid -and (Get-OptionalObject $guid)) {
                throw 'Recorded object still exists outside the expected OU. Manual review required.'
            }
        }
    }
    Remove-Item -LiteralPath $StatePath -ErrorAction Stop
    Write-Output 'Cleanup complete. Audit policy and installed modules were not changed.'
    return
}

Import-Module DSInternals -MinimumVersion 7.2 -ErrorAction Stop
$cmd = Get-Command 'DSInternals\Add-ADReplSidHistory' -ErrorAction Stop
if (-not $cmd.Parameters.ContainsKey('DeleteSourceObject')) {
    throw 'The required intra-domain parameter set is unavailable.'
}
$domain = Get-ADDomain @ad
$dc = Get-ADDomainController -Identity (Get-ADRootDSE @ad).dnsHostName @ad
if ($dc.IsReadOnly) { throw 'A writable domain controller is required.' }
$runId = [guid]::NewGuid().ToString('N')
$suffix = $runId.Substring(0, 12)
$ouName = "ART-T1134-005-$runId"
$ouDN = "OU=$ouName,$($domain.DistinguishedName)"
$script:state = [ordered]@{
    Schema = 1
    RunId = $runId
    Server = $Server
    DomainDN = $domain.DistinguishedName
    Marker = "AtomicRedTeam:T1134.005:$runId"
    OuDN = $ouDN
    OuGuid = ''
    SourceDN = "CN=ARTSRC-$suffix,$ouDN"
    SourceGuid = ''
    SourceSID = ''
    DestinationDN = "CN=ARTDST-$suffix,$ouDN"
    DestinationGuid = ''
    StartedUtc = [DateTime]::UtcNow.ToString('o')
    CompletedUtc = ''
    Status = 'Preparing'
}

# Atomically reserve a NEW manifest; never overwrite another run's state.
$stream = [IO.File]::Open($StatePath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
$stream.Dispose()
Save-State

try {
    $ou = New-ADOrganizationalUnit -Name $ouName -Path $domain.DistinguishedName -Description $state.Marker -ProtectedFromAccidentalDeletion $true -PassThru @ad
    $state.OuGuid = $ou.ObjectGUID.ToString()
    Save-State
    $source = New-ADUser -Name "ARTSRC-$suffix" -SamAccountName "ARTSRC-$suffix" -Path $ouDN -Description $state.Marker -Enabled $false -PassThru @ad
    $state.SourceGuid = $source.ObjectGUID.ToString()
    $state.SourceSID = $source.SID.Value
    Save-State
    $destination = New-ADUser -Name "ARTDST-$suffix" -SamAccountName "ARTDST-$suffix" -Path $ouDN -Description $state.Marker -Enabled $false -PassThru @ad
    $state.DestinationGuid = $destination.ObjectGUID.ToString()
    Save-State

    # Re-read exact objects on the same DC before issuing the destructive RPC.
    foreach ($entry in @(@($state.SourceDN, $state.SourceGuid), @($state.DestinationDN, $state.DestinationGuid))) {
        $user = Get-ADUser -Identity $entry[0] -Properties Description, SIDHistory, MemberOf @ad
        Assert-OwnedObject $user 'user' $entry[1]
        if ($user.Enabled -or @($user.SIDHistory).Count -gt 0 -or @($user.MemberOf).Count -gt 0) {
            throw 'Test account state changed. Refusing SID history migration.'
        }
    }
    $state.Status = 'Executing'
    Save-State
    Write-Output ("T1134.005 RPC start UTC: {0}; PowerShell PID: {1}" -f [DateTime]::UtcNow.ToString('o'), $PID)
    DSInternals\Add-ADReplSidHistory -SourcePrincipal $state.SourceDN -DestinationPrincipal $state.DestinationDN -DeleteSourceObject -Verbose @ad

    $after = Get-ADUser -Identity ([guid]$state.DestinationGuid) -Properties SIDHistory @ad
    $sids = @($after.SIDHistory | ForEach-Object { $_.Value })
    $sourceGone = $null -eq (Get-OptionalObject $state.SourceDN)
    if ($sids -notcontains $state.SourceSID -or -not $sourceGone) {
        throw 'RPC returned but the expected postconditions were not observed.'
    }
    $state.Status = 'Verified'
    $state.CompletedUtc = [DateTime]::UtcNow.ToString('o')
    Save-State
    [pscustomobject]@{
        Destination = $after.DistinguishedName
        SourceSID = $state.SourceSID
        SourceSIDPresent = $true
        SourceDeleted = $true
        StatePath = $StatePath
    }
}
catch {
    Write-Warning "Test did not finish successfully. Keep $StatePath and run Cleanup after investigation."
    throw
}
