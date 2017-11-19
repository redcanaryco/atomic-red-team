# Service Installation

MITRE ATT&CK Technique: [T1050](https://attack.mitre.org/wiki/Technique/T1050)

## sc.exe

Input:

    sc create TestService binPath="C:\Path\file.exe"


## PowerShell

Input:

    powershell New-Service -Name "TestService" -BinaryPathName "C:\Path\file.exe"

## Test Script
    [Service.cs](https://github.com/redcanaryco/atomic-red-team/blob/master/Windows/Payloads/Service.cs)
