## Account Discovery

MITRE ATT&CK Technique: [T1087](https://attack.mitre.org/wiki/Technique/T1087)

### Enumerate Groups and users

Input:

    groups

Input:

    id

Input:

    dscl . list /Groups

Input:

    dscl . list /Users

Input:

    dscl . list /Users | grep -v '_'

Input:

    dscacheutil -q group

Input:

dscacheutil -q user
