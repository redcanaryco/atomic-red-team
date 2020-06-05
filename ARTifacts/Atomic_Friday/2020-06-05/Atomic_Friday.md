# Atomic Friday - 06-05-2020

Detection Engineering Philosophy in a nutshell

- https://twitter.com/mattifestation/status/1263416936517468167?s=20

Additional References:
- https://posts.specterops.io/detection-spectrum-198a0bfb9302
- https://posts.specterops.io/detection-in-depth-a2392b3a7e94

## Do it live

What data do I have?

```
| metadata type=sourcetypes index=botsv3 | eval firstTime=strftime(firstTime,"%Y-%m-%d %H:%M:%S") | eval lastTime=strftime(lastTime,"%Y-%m-%d %H:%M:%S") | eval recentTime=strftime(recentTime,"%Y-%m-%d %H:%M:%S") | sort - totalCount
```

Stats
Endpoint count
`(index="botsv3" OR index="botsv2") |  stats values(ComputerName)`
Event types
`(index="botsv3" OR index="botsv2")  |  stats values(type)`


```
(index="botsv3" OR index="botsv2") powershell.exe source="WinEventLog:Microsoft-Windows-Sysmon/Operational" | stats values(CommandLine) by Computer
```


## Technique: Scheduled Tasks
- MITRE [T1053](https://attack.mitre.org/techniques/T1053/)
- Atomic Red Team [T1053](https://github.com/redcanaryco/atomic-red-team/blob/7d07686f600c0fb3bba468c987eb4e4faea83fa9/atomics/T1053/T1053.md)

Find all Schtasks:

`(index="botsv3" OR index="botsv2") schtasks.exe`

What data sources did we receive?


### Now let's see all the CommandLine?

`(index="botsv3" OR index="botsv2") schtasks.exe | stats values(CommandLine)`

`(index="botsv3" OR index="botsv2") schtasks.exe | stats values(CommandLine) by Computer`

`(index="botsv3" OR index="botsv2") schtasks.exe | stats values(CommandLine) by host`

### Change source (WinEventLog:Security)

`(index="botsv3") source="WinEventLog:Security"  schtasks.exe | stats values(Process_Command_Line) by  Creator_Process_Name`


`(index="botsv2") source="WinEventLog:Security"  schtasks.exe | stats values(Process_Command_Line) by ComputerName`

### What created this?

`(index="botsv3" OR index="botsv2") source="WinEventLog:Microsoft-Windows-Sysmon/Operational" schtasks.exe | stats values(Image) by ParentImage`

`(index="botsv3" OR index="botsv2") source="WinEventLog:Microsoft-Windows-Sysmon/Operational" schtasks.exe ParentImage=*\\powershell.exe| stats values(Image) by ParentImage ParentCommandLine`

### Begin Tuning Schtasks Search

`(index="botsv3" OR index="botsv2") source="WinEventLog:Microsoft-Windows-Sysmon/Operational" schtasks.exe CommandLine=*powershell.exe*| stats values(CommandLine) by Computer`

`(index="botsv3" OR index="botsv2") source="WinEventLog:Microsoft-Windows-Sysmon/Operational" schtasks.exe CommandLine!="*\Office Automatic Updates*" CommandLine!="*\Office ClickToRun*" | stats values(CommandLine) by Computer`

but - because we know what we want to fire on - 

I want to alert on each time someone creates a task:

`(index="botsv3" OR index="botsv2") source="WinEventLog:Microsoft-Windows-Sysmon/Operational" schtasks.exe CommandLine=*Create* ParentImage!=*\\OfficeClicktoRun.exe | stats values(CommandLine) by Computer`

Alert for non-standard parent processes.

### Saved Reports

`(index="botsv3" OR index="botsv2") source="WinEventLog:Microsoft-Windows-Sysmon/Operational" schtasks.exe CommandLine=*Create* ParentImage!=*\\OfficeClicktoRun.exe | stats values(CommandLine) by Computer`

### Prep for alert:
`(index="botsv3" OR index="botsv2") source="WinEventLog:Microsoft-Windows-Sysmon/Operational" schtasks.exe | table Computer, User, CommandLine, _time`

`(index="botsv3" OR index="botsv2") source="WinEventLog:Microsoft-Windows-Sysmon/Operational" schtasks.exe CommandLine=*Create* ParentImage!=*\\OfficeClicktoRun.exe | table Computer, User, CommandLine, _time`

## Technique: Powershell

Sometimes we may not see the whole picture looking at process command line (Sysmon). What if we had Powershell transactions logs?

`(index="botsv3" OR index="botsv2") powershell.exe source="WinEventLog:Microsoft-Windows-PowerShell/Operational"`

Sysmon - 

`(index="botsv3" OR index="botsv2") powershell.exe source="WinEventLog:Microsoft-Windows-Sysmon/Operational" | stats values(CommandLine) by Computer`

### Alerts

Email alerts:

Save “Saved Search” with (or change) for a “clean” alert:

`| table Computer, User, CommandLine, _time`

Recommend throttling each alert by current estimated time to remediation.
Ex - Throttle 3 days
