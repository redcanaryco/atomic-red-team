# Re-Opened Applications

MITRE ATT&CK Technique: [T1164](https://attack.mitre.org/wiki/Technique/T1164)

### Plist method

create a custom plist:

    ~/Library/Preferences/com.apple.loginwindow.plist

or

    ~/Library/Preferences/ByHost/com.apple.loginwindow.*.plist

### Mac Defaults

Create:

    sudo defaults write com.apple.loginwindow LoginHook /path/to/script

Delete:

    sudo defaults delete com.apple.loginwindow LoginHook


[Reference](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CustomLogin.html)
