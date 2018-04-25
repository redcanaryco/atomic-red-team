# InstallUtil

## MITRE ATT&CK Technique:
[T1118](https://attack.mitre.org/wiki/Technique/T1118)

## Execution Examples:

### Input:

    x86 - C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /logfile= /LogToConsole=false /U AllTheThings.dll

    x64 - C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe /logfile= /LogToConsole=false /U AllTheThings.dll

## Test Script

[InstallUtilBypass.cs](https://github.com/redcanaryco/atomic-red-team/blob/master/Windows/Payloads/InstallUtilBypass.cs)
