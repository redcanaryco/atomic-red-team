# Invoke-AtomicRedTeam

## Setup

### Install Atomic Red Team

* Be sure to get permission and necessary approval before conducting test's. Unauthorized testing is a bad decision
and can potentially be a resume-generating event.

* Set up a test machine that would be similar to the build in your environment. Be sure you have your collection/EDR
solution in place, and that the endpoint is checking in and active. It is best to have AV turned off.

We made installing Atomic Red Team extremely easy.

Once the environment is ready, run the following PowerShell one liner as Administrator:

`powershell.exe "IEX (New-Object Net.WebClient).DownloadString('http://psInstall.AtomicRedTeam.com')"`

[Source](install-atomicredteam.ps1)

By default, it will download and Install Atomic Red Team to `c:\AtomicRedTeam`

Running the [Install script](install-atomicredteam.ps1) locally provides three parameters:

InstallPath
- Where ART is to be Installed

    `Install-AtomicRedTeam.ps1 -InstallPath c:\tools\`

DownloadPath
- Where ART is to be downloaded

    `Install-AtomicRedTeam.ps1 -DownloadPath c:\tools\`

Verbose
- Verbose output during Installation

    `Install-AtomicRedTeam.ps1 -verbose`

### Manual


`set-executionpolicy Unrestricted`

[PowerShell-Yaml](https://github.com/cloudbase/powershell-yaml) is required to parse Atomic yaml files:


`Install-Module -Name powershell-yaml`

`Import-Module .\Invoke-AtomicRedTeam.psm1`

## Getting Started

#### Execute All Tests

Execute all Atomic tests:

```powershell
Invoke-AtomicTest All
```
#### Execute All Tests - Specific Directory

Specify a path to atomics folder, example C:\AtomicRedTeam\atomics

```powershell
Invoke-AtomicTest All -PathToAtomicsFolder C:\AtomicRedTeam\atomics
```

### Display Test Details without Executing the Test

```powershell
Invoke-AtomicTest All -ShowDetails -InformationAction Continue
```

Using the `ShowDetails` switch causes the test details to be printed to the screen and allows for easy copy and paste execution.
Note: you may need to change the path with the `PathToAtomicsFolder` parameter.

#### Execute All Attacks for a Given Technique

```powershell
Invoke-AtomicTest T1117
```

By default, test execution details are written to `Invoke-AtomicTest-ExecutionLog.csv` in the current directory.

#### Specify an Alternate Path for the Execution Log

```powershell
Invoke-AtomicTest T1117 -ExecutionLogPath 'C:\Temp\mylog.csv'
```

By default, test execution details are written to `Invoke-AtomicTest-ExecutionLog.csv` in the current directory. Use the `-ExecutionLogPath` parameter to write to a different file. Nothing is logged in the execution log when only running pre-requisite checks with `-CheckPrereqs` or cleanup commands with `-Cleanup`. Use the `-NoExecutionLog` switch to not write execution details to disk.

#### Check that Prerequistes for a Given Technique are met

```powershell
Invoke-AtomicTest T1117 -CheckPrereqs
```

For the "command_prompt" executor, if any of the prereq_command's return a non-zero exit code, the pre-requisites are not met. Example: **fltmc.exe filters | findstr #{sysmon_driver}**
For the "powershell" executor, the prereq_command's are run as a script block and the script must return 0 if the pre-requisites are met. Example: **if(Test-Path C:\Windows\System32\cmd.exe) { 0 } else { -1 }**

#### Execute Specific Attacks (by Attack Number) for a Given Technique

```powershell
Invoke-AtomicTest T1117 -TestNumbers 1, 2
```

#### Execute Specific Attacks (by Attack Name) for a Given Technique

```powershell
Invoke-AtomicTest T1117 -TestNames "Regsvr32 remote COM scriptlet execution","Regsvr32 local DLL execution"
```
#### Run the Cleanup Commands For the Specified Test

```powershell
Invoke-AtomicTest T1089 -TestNames "Uninstall Sysmon" -Cleanup
```

## Additional Examples

If you would like output when running tests using the following:

#### Informational Stream

```powershell
Invoke-AtomicTest T1117 -InformationAction Continue
```

#### Verbose Stream

```powershell
Invoke-AtomicTest T1117 -Verbose
```

#### Debug Stream

```powershell
Invoke-AtomicTest T1117 -Debug
```

#### Confirm

To run all tests without confirming them run using the Confirm switch to false

```powershell
Invoke-AtomicTest T1117 -Confirm:$false
```

Or you can set your `$ConfirmPreference` to 'Medium'

```powershell
$ConfirmPreference = 'Medium'
Invoke-AtomicTest T1117
```
