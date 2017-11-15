# Timestomp

MITRE ATT&CK Technique: [T1099](https://attack.mitre.org/wiki/Technique/T1099)

## Timestomp with PowerShell

    echo "Atomic Test File" > test.txt
    PowerShell.exe -com {$file=(gi test.txt);$date='06/06/2006 12:12 pm';$file.LastWriteTime=$date;$file.LastAccessTime=$date;$file.CreationTime=$date}

