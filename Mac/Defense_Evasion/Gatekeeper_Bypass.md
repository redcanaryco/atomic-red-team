# Gatekeeper Bypass

MITRE ATT&CK Technique: [T1144](https://attack.mitre.org/wiki/Technique/T1144)


    sudo xattr -r -d com.apple.quarantine /path/to/MyApp.app

    sudo spctl --master-disable
