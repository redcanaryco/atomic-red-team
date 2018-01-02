# Disabling Security Tools

MITRE ATT&CK Technique: [T1089](https://attack.mitre.org/wiki/Technique/T1089)


## Disabling By Tool:

### Carbon Black Response
    sudo launchctl unload /Library/LaunchDaemons/com.carbonblack.daemon.plist

### LittleSnitch
    sudo launchctl unload /Library/LaunchDaemons/at.obdev.littlesnitchd.plist

### OpenDNS Umbrella
    sudo launchctl unload /Library/LaunchDaemons/com.opendns.osx.RoamingClientConfigUpdater.plist
