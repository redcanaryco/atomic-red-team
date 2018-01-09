## System Owner/User Discovery

MITRE ATT&CK Technique: [T1033](https://attack.mitre.org/wiki/Technique/T1033)

### cmd.exe

    "cmd.exe" /C whoami

### wmic.exe

    wmic useraccount get /ALL

### quser

Remote:

    quser /SERVER:"<computername>"

Local:

    quser

### qwinsta

Remote:

    qwinsta.exe" /server:<computername>

Local:

    qwinsta.exe
