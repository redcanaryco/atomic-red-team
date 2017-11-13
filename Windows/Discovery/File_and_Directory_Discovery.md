## File and Directory Discovery

MITRE ATT&CK Technique: [T1083](https://attack.mitre.org/wiki/Technique/T1083)

### Directory listing

Input:

    dir /s c:\ >> %temp%\download
    dir /s "c:\Documents and Settings" >> %temp%\download
    dir /s "c:\Program Files\" >> %temp%\download
    dir /s d:\ >> %temp%\download
