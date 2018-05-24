## Create the directory for invocation proofs
if(-not (Test-Path $env:TEMP\AtomicRedTeam))
{
    $null = New-Item -Type Directory $env:TEMP\AtomicRedTeam
}

## Register for cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Remove-Item $env:TEMP\AtomicRedTeam -Recurse
}

$actions = @{
    'Windows/Execution/BitsAdmin' = {

        ## Extract the command from the page
        $commands = Get-ActionCode -Path $PSScriptRoot/../Windows/Execution/BitsAdmin.md -SectionName bitsadmin.exe

        ## Launch the action
        Invoke-Expression $commands[0]
    }
    
    'Windows/Execution/Trusted_Developer_Utilities/MSBuild' = {

        ## Extract the command from the page
        $commands = Get-ActionCode -Path $PSScriptRoot/../Windows/Execution/Trusted_Developer_Utilities.md -SectionName msbuild.exe
        $commandToInvoke,$commandArgs = $commands[0] -split ' '

        ## Run it, but with the real MSBuildBypass we've got in /Windows/Payloads
        & $commandToInvoke ..\Windows\Payloads\MSBuildBypass.csproj
    }

    'Windows/Lateral_Movement/Remote_Desktop_Protocol_Hijack' = {

        ## Extract the command from the page
        $commands = Get-ActionCode -Path $PSScriptRoot/../Windows/Lateral_Movement/Remote_Desktop_Protocol.md -SectionName 'RDP hijacking'

        ## Launch the actions
        foreach($command in $commands)
        {
            Invoke-Expression $command 2>&1
        }
    }

    'Windows/Defense_Evasion/Indicator_Removal_on_Host/System' = {

        if($Force -or $PSCmdlet.ShouldContinue("Do you with to clear the System log?", "Confirm impactful change"))
        {
            ## Extract the command from the page
            $commands = Get-ActionCode -Path $PSScriptRoot/../Windows/Defense_Evasion/Indicator_Removal_on_Host.md -SectionName 'wevtutil' |
                Where-Object { $_ -match 'System' }
            
            ## Launch the action
            Invoke-Expression $commands[0]
        }
    }

}

function Get-ActionCode
{
    param($Path, $SectionName)

    $sections = Get-Content $Path -Delimiter '###'
    ,@($sections |
        Where-Object { $_ -like "*$SectionName*" } |
        Select-String "    (.*)" -AllMatches |
        ForEach-Object { $_.Matches.Captures.Value.Trim() })
}

function Invoke-Action
{
    param(
        [Parameter(Mandatory, Position = 0)]
        $Action,

        [Parameter()]
        [Switch] $Force       
    )

    $Action = $Action -replace "\\","/"

    foreach($possibleAction in $actions.Keys)
    {
        if($possibleAction -like $Action)
        {
            $actionCode = $actions[$possibleAction]
            & $actionCode
        }
    }
    
}

function Get-Action
{
    param(
        [Parameter(Position = 0)]
        $Action = "*"
    )

    $Action = $Action -replace "\\","/"

    foreach($possibleAction in $actions.Keys)
    {
        if($possibleAction -like $Action)
        {
            $possibleAction
        }
    }
    
}