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

Single Endpoint

    for /F “tokens=1,2” %i in (‘qwinsta /server:<COMPUTERNAME> ^| findstr “Active Disc”‘) do @echo %i | find /v “#” | find /v “console” || echo %j > usernames.txt

Multiple Endpoints

    @FOR /F %n in (computers.txt) DO @FOR /F “tokens=1,2” %i in (‘qwinsta /server:%n ^| findstr “Active Disc”’) do @echo %i | find /v “#” | find /v “console” || echo %j > usernames.txt
