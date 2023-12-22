New-Item $PROFILE -Force
Set-Variable -Name "InvokePath" -Value (Get-Item /usr/local/share/powershell/Modules/Invoke-AtomicRedTeam/**/Invoke-AtomicRedTeam.psd1).FullName
Write-Output @"
Import-Module $InvokePath -Force
`$PSDefaultParameterValues`["Invoke-AtomicTest:PathToAtomicsFolder"] = "/workspaces/atomic-red-team/atomics";
`$PSDefaultParameterValues`["Invoke-AtomicTest:ExecutionLogPath"]="$HOME/AtomicRedTeam/execution.csv";
"@ > $PROFILE