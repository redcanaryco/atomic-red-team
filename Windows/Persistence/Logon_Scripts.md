# Logon Scripts

## MITRE ATT&CK Technique:
[T1037](https://attack.mitre.org/wiki/Technique/T1037)


## Input:

### Add path and any command line variables--

    REG.exe ADD HKCU\Environment /v UserInitMprLogonScript /t REG_MULTI_SZ /d "<path of evil> <commandline switch of evil>"
