@echo off
start %USERPROFILE%\Downloads\psiphon3.exe
timeout /t 20 >nul 2>&1
Taskkill /IM msedge.exe /F >nul 2>&1
Taskkill /IM psiphon3.exe /F >nul 2>&1
Taskkill /IM psiphon-tunnel-core.exe /F >nul 2>&1
