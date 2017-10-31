# File Deletion

MITRE ATT&CK Technique: [T1002](https://attack.mitre.org/wiki/Technique/T1002)

## PowerShell

    powershell.exe dir c:\* -Recurse | Compress-Archive -DestinationPath C:\test\Data.zip

## Rar

    rar a -r exfilthis.rar *.docx
