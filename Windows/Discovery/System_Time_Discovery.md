# System Time Discovery

MITRE ATT&CK Technique: [T1124](https://attack.mitre.org/wiki/Technique/T1124)

### Net Time


Local:

    net time

Remote:

    net time \\<hostname>

### w32time

   w32tm /tz

### PowerShell

    powershell.exe Get-Date
