# Security Software Discovery

MITRE ATT&CK Technique: [T1018](https://attack.mitre.org/wiki/Technique/T1063)

### netsh

    netsh.exe advfirewall firewall

### tasklist

    tasklist.exe


### PowerShell

    powershell.exe get-process | ?{$_.Description -like "*virus*"}

#### CarbonBlack

    powershell.exe get-process | ?{$_.Description -like "*carbonblack*"}

#### Windows Defender

    powershell.exe get-process | ?{$_.Description -like "*defender*"}
