New-Item $PROFILE -Force
Invoke-Expression (Invoke-WebRequest 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
Install-AtomicRedTeam
Write-Output @"
Import-Module $HOME/AtomicRedTeam/invoke-atomicredteam/Invoke-AtomicRedTeam.psd1 -Force
`$PSDefaultParameterValues`["Invoke-AtomicTest:PathToAtomicsFolder"] = "/workspaces/atomic-red-team/atomics";
`$PSDefaultParameterValues`["Invoke-AtomicTest:ExecutionLogPath"]="$HOME/AtomicRedTeam/execution.csv";
"@ > $PROFILE