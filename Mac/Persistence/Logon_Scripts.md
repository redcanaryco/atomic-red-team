# Logon Scripts

## MITRE ATT&CK Technique:
[T1037](https://attack.mitre.org/wiki/Technique/T1037)


## Root level loginhook (executes for all users)

### Create the required plist file

    sudo touch /private/var/root/Library/Preferences/com.apple.loginwindow.plist

### Populate the plist with the location of your shell script

    sudo defaults write com.apple.loginwindow LoginHook /Library/Scripts/AtomicRedTeam.sh

### User level loginhook

### Create the required plist file in the target user's Preferences directory

	touch /Users/$USER/Library/Preferences/com.apple.loginwindow.plist

### Populate the plist with the location of your shell script

	defaults write com.apple.loginwindow LoginHook /Library/Scripts/AtomicRedTeam.sh
