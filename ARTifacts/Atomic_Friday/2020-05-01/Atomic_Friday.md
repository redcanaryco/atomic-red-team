# Atomic Friday - 05-01-2020

## Setup

My environment today is built with DetectionLab.

>This lab has been designed with defenders in mind. Its primary purpose is to allow the user to quickly build a Windows domain that comes pre-loaded with security tooling and some best practices when it comes to system logging configurations. It can easily be modified to fit most needs or expanded to include additional hosts.


Get it here:
https://github.com/clong/DetectionLab

Follow: [@DetectionLab](https://twitter.com/DetectionLab)


<img src="https://github.com/clong/DetectionLab/raw/master/img/DetectionLab.png" alt="DetectionLab" width="200"/>


We will be working from WIN10 system.

`$PSVersionTable`
```
Name                           Value
----                           -----
PSVersion                      5.1.18362.1
PSEdition                      Desktop
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
BuildVersion                   10.0.18362.1
CLRVersion                     4.0.30319.42000
...
```

## Get Invoke-AtomicRedTeam

<img src="https://www.redcanary.com/wp-content/uploads/image2-25.png" alt="Atomic" width="200"/>

https://github.com/redcanaryco/invoke-atomicredteam

```
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1')
Install-AtomicRedTeam -getAtomics
```
This will install `invoke-atomicredteam` and download `Atomics` folder from Atomic Red Team.

Note: 
- `Set-ExecutionPolicy -Scope CurrentUser unrestricted`
- `set-executionpolicy unrestricted`
- Disable AV. 

Atomics folder:
https://github.com/redcanaryco/atomic-red-team/tree/master/atomics

## Before Update

We're going to modify T1086 - BloodHound

https://github.com/redcanaryco/atomic-red-team/tree/23620c707ac1ed89e4207a39488f9214cf3c6e1e/atomics/T1086

## After Update

SharpHound PR
- https://github.com/redcanaryco/atomic-red-team/pull/955
- https://github.com/redcanaryco/atomic-red-team/pull/962
- Added src dir (removed payloads)
- Added input arguments
- Added prereqs


SharpHound ingestor: 
https://github.com/BloodHoundAD/BloodHound/blob/master/Ingestors/SharpHound.ps1


## Local Execution

`Invoke-AtomicTest T1086 -ShowDetailsBrief`

```
PathToAtomicsFolder = C:\AtomicRedTeam\atomics

T1086-1 Mimikatz
T1086-2 Run BloodHound from local disk
T1086-3 Run Bloodhound from Memory using Download Cradle
```

Select test and show details:

`Invoke-AtomicTest T1086 -TestNumbers 2 -ShowDetails`

Check Prerequisits:

`Invoke-AtomicTest T1086 -TestNumbers 2 -CheckPrereqs`

```
CheckPrereq's for: T1086-2 Run BloodHound from local disk
Prerequisites not met: T1086-2 Run BloodHound from local disk
        [*] SharpHound.ps1 must be located at C:\AtomicRedTeam\atomics\T1086\src

Try installing prereq's with the -GetPrereqs switch
```

Get Prerequisits:

`Invoke-AtomicTest T1086 -TestNumbers 2 -GetPrereqs`

```
GetPrereq's for: T1086-2 Run BloodHound from local disk
Attempting to satisfy prereq: SharpHound.ps1 must be located at C:\AtomicRedTeam\atomics\T1086\src
Prereq successfully met: SharpHound.ps1 must be located at C:\AtomicRedTeam\atomics\T1086\src
```

Execute:

`Invoke-AtomicTest T1086 -TestNumbers 2`

```
Import and Execution of SharpHound.ps1 from C:\AtomicRedTeam\atomics\T1086\src
-----------------------------------------------
Initializing SharpHound at 4:31 PM on 4/30/2020
-----------------------------------------------

Resolved Collection Methods: Group, Sessions, Trusts, ACL, ObjectProps, LocalGroups, SPNTargets, Container

[+] Creating Schema map for domain WINDOMAIN.LOCAL using path CN=Schema,CN=Configuration,DC=WINDOMAIN,DC=LOCAL
[+] Cache File not Found: 0 Objects in cache

[+] Pre-populating Domain Controller SIDS
Status: 0 objects finished (+0) -- Using 81 MB RAM
Status: 71 objects finished (+71 ∞)/s -- Using 86 MB RAM
Enumeration finished in 00:00:00.6317770
Compressing data to C:\Users\VAGRAN~1.WIN\AppData\Local\Temp\20200430163109_BloodHound.zip
You can upload this file directly to the UI

SharpHound Enumeration Completed at 4:31 PM on 4/30/2020! Happy Graphing!

Done executing test: T1086-2 Run BloodHound from local disk
```

Where are my reports!?

`-OutputDirectory $env:Temp`

`ls $env:Temp`

`20200430163109_BloodHound.zip`

Time to cleanup

`Invoke-AtomicTest T1086 -TestNumbers 2 -Cleanup`

```
Command (with inputs):
Remove-Item C:\AtomicRedTeam\atomics\T1086\src\SharpHound.ps1 -Force -ErrorAction Ignore
Remove-Item $env:Temp\*BloodHound.zip -Force
```

