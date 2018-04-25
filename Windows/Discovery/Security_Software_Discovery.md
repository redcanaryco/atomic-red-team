# Security Software Discovery

## MITRE ATT&CK Technique:
[T1063](https://attack.mitre.org/wiki/Technique/T1063)

## netsh

    netsh.exe advfirewall firewall show all profiles

## tasklist

### Input:

    tasklist.exe

### Input:

    tasklist.exe | findstr virus

### Input:

    tasklist.exe | findstr cb

### Input:

    tasklist.exe | findstr defender


### PowerShell

    powershell.exe get-process | ?{$_.Description -like "*virus*"}

#### CarbonBlack

    powershell.exe get-process | ?{$_.Description -like "*carbonblack*"}

#### Windows Defender

    powershell.exe get-process | ?{$_.Description -like "*defender*"}
