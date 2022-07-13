@echo off

for %%v in (3, 1, 2, 5, 4) do (
    for /F "usebackq tokens=2* skip=2" %%a in (
        `reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\%%v\PowerShellEngine" /v ApplicationBase 2^> nul`
    ) do if exist %%b (
        set powershell="%%b\powershell.exe"
        goto found
    )
)

echo PowerShell was not found. Trying call 'as is'
powershell %*

goto exit

:found

echo PowerShell path: %powershell% 

%powershell% %*


:exit