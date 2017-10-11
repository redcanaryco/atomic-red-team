## File and Directory Discovery

MITRE ATT&CK Technique: [T1083](https://attack.mitre.org/wiki/Technique/T1083)

### Directory listing

Input:

    dir c:\ >> %temp%\download
    dir "c:\Documents and Settings" >> %temp%\download
    dir "c:\Program Files\" >> %temp%\download
    dir d:\ >> %temp%\download
