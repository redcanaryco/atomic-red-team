---
layout: default
---

# Getting Started - PowerShell Invoke-AtomicRedTeam

1. [Install Atomic Red Team](#install-atomic-red-team)
2. [Generate Tests](#generate-tests)
3. [Execute Tests](#execute-tests)
4. [Other Examples](#Other-Examples)   

## Install Atomic Red Team

* Be sure to get permission and necessary approval before conducting test's. Unauthorized testing is a bad decision
and can potentially be a resume-generating event.

* Set up a test machine that would be similar to the build in your environment. Be sure you have your collection/EDR
solution in place, and that the endpoint is checking in and active. It is best to have AV turned off.

We made installing Atomic Red Team extremely easy.

Once the environment is ready, run the following PowerShell one liner as Administrator:

`powershell.exe "IEX (New-Object Net.WebClient).DownloadString('http://psinstall.AtomicRedTeam.com')"`

[Source](https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/execution-frameworks/Invoke-AtomicRedTeam/install-AtomicRedTeam.ps1)

By default, it will download and install Atomic Red Team to `c:\tools\`

Running the [install script](https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/execution-frameworks/Invoke-AtomicRedTeam/install-AtomicRedTeam.ps1) locally provides three parameters:

InstallPath
- Where ART is to be installed

    `install-AtomicRedTeam.ps1 -InstallPath c:\tools\`

DownloadPath
- Where ART is to be downloaded

    `install-AtomicRedTeam.ps1 -DownloadPath c:\tools\`

Verbose
- Verbose output during installation

    `install-AtomicRedTeam.ps1 -verbose`

### Manual Installation

To manually install Invoke-AtomicRedTeam:

`set-executionpolicy Unrestricted`

[PowerShell-Yaml](https://github.com/cloudbase/powershell-yaml) is required to parse Atomic yaml files:

`Install-Module -Name powershell-yaml`

`Import-Module .\Invoke-AtomicRedTeam.psm1`

## Generate Tests

This process generates all Atomic tests and allows for easy copy and paste execution.
Note: you may need to change the path.

    Invoke-AllAtomicTests -GenerateOnly

### Execute All Tests

Execute all Atomic tests:

    Invoke-AllAtomicTests

### Execute All Tests - Specific Directory

Specify a path to atomics folder, example C:\AtomicRedTeam\atomics

    Invoke-AllAtomicTests -path C:\AtomicRedTeam\atomics

### Execute a Single test

    $T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
    Invoke-AtomicTest $T1117

## Other Examples

If you would like output when running tests using the following:

#### Informational Stream

```powershell
Invoke-AtomicTest $T1117 -InformationAction Continue
```

#### Verbose Stream

```powershell
Invoke-AtomicTest $T1117 -Verbose
```

#### Debug Stream

```powershell
Invoke-AtomicTest $T1117 -Debug
```

#### WhatIf

If you would like to see what would happen without running the test

```powershell
Invoke-AtomicTest $T1117 -WhatIf
```

#### Confirm

To run all tests without confirming them run using the Confirm switch to false

```powershell
Invoke-AtomicTest $T1117 -Confirm:$false
```

Or you can set your `$ConfirmPreference` to 'Medium'

```powershell
$ConfirmPreference = 'Medium'
Invoke-AtomicTest $T1117
```
