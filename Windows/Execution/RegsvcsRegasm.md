## Regsvcs/Regasm

MITRE ATT&CK Technique: [T1121](https://attack.mitre.org/wiki/Technique/T1121)

### Execution Examples:

[DLL](https://github.com/redcanaryco/atomic-red-team/tree/master/Windows/Payloads/AllTheThings)

Input:

    x86 C:\Windows\Microsoft.NET\Framework\v4.0.30319\regsvcs.exe AllTheThings.dll

    x64 C:\Windows\Microsoft.NET\Framework64\v4.0.30319\regsvcs.exe AllTheThings.dll


    x86 C:\Windows\Microsoft.NET\Framework\v4.0.30319\regasm.exe /U AllTheThings.dll

    x64 C:\Windows\Microsoft.NET\Framework64\v4.0.30319\regasm.exe /U AllTheThings.dll


## Test Script
[RegSvcsRegAsmBypass.cs](https://github.com/redcanaryco/atomic-red-team/blob/master/Windows/Payloads/RegSvcsRegAsmBypass.cs)
