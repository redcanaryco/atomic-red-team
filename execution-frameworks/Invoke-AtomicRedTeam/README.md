# Invoke-AtomicRedTeam

## Setup

### Install Atomic Red Team

Get started with our simple Install script:

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

### Generate Tests

This process generates all Atomic tests and allows for easy copy and paste execution.
Note: you may need to change the path.

    Invoke-AllAtomicTests -GenerateOnly

#### Execute All Tests

Execute all Atomic tests:

    Invoke-AllAtomicTests

#### Execute All Tests - Specific Directory

Specify a path to atomics folder, example C:\AtomicRedTeam\atomics

    Invoke-AllAtomicTests -path C:\AtomicRedTeam\atomics


#### Execute a Single Test

```powershell
$T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
Invoke-AtomicTest $T1117
```

## Additional Examples

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
