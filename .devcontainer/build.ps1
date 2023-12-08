New-Item $PROFILE -Force

Write-Output @"
`$PSDefaultParameterValues`["Invoke-AtomicTest:PathToAtomicsFolder"] = "/workspaces/atomic-red-team/atomics";
`$PSDefaultParameterValues`["Invoke-AtomicTest:ExecutionLogPath"]="/workspaces/atomic-red-team/execution_log.csv";
"@ > $PROFILE
sudo pwsh