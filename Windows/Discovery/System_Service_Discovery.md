# System Service Discovery

## MITRE ATT&CK Technique:
[T1007](https://attack.mitre.org/wiki/Technique/T1007)

## Tasklist.exe

### Input:

    tasklist.exe

## sc.exe

### Input:

    sc query

### Input:

    sc query state= all

## Start/Stop a service

    sc start <service name>

### Stop:

    sc stop <service name>


## GUI:

    services.msc

## WMIC.exe

    wmic service where (displayname like "%<whatever>%") get name
