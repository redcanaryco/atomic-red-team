# PsExec
## MITRE ATT&CK Software:
[S0029] (https://attack.mitre.org/wiki/Software/S0029)

### PsExec is a light-weight telnet-replacement that lets you execute processes on other systems, complete with full interactivity for console applications, without having to manually install client software.

### PsExec lateral movement:

#### Input:

`Psexec -accepteula \\host cmd`

#### Artifacts:
##### The Windows Event ID 4689 - A process has exited
If you kill a PsExec process, you might also need to manually remove the background service:

`sc.exe \\workstation64 delete psexesvc`

## Reference:
https://docs.microsoft.com/en-us/sysinternals/downloads/psexec
