function Test-Target {
    param (
        [string]$Target,
        [string]$Timeout = 5
    )

    try {
        Invoke-WebRequest -Uri $Target -ErrorAction Stop -TimeoutSec $Timeout -SkipHttpErrorCheck
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-WordlistScan {
    param (
        [string]$Target,
        [string]$Wordlist,
        [string]$OutputFile,
        [string]$Timeout
    )

    if ($(Test-Target -Target $Target -Timeout $Timeout) -eq $false) {
        Write-Output "Error: Target is not reachable"
        exit 1
    }

    [string[]]$Wordlist = Get-Content $Wordlist
    $Results = @()

    foreach ($Word in $Wordlist) {
        $Url = $Target + "/" + $Word
        $Response = Invoke-WebRequest -Uri "$Url" -Method HEAD -ErrorAction SilentlyContinue -TimeoutSec $Timeout -SkipHttpErrorCheck

        if ($Response.StatusCode -ge 200 -and $Response.StatusCode -lt 400) {
            $Results += $Url
        }
    }

    if ($Results.Count -eq 0) {
        Write-Output "No valid paths found"
        exit 1
    }
    foreach ($Result in $Results) {
        Write-Output $Result | Out-File -Append -FilePath $OutputFile
    }
}
