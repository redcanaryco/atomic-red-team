# Launch Agent

## MITRE ATT&CK Technique:
[T1159](https://attack.mitre.org/wiki/Technique/T1159)

## Input:

	Filename: .client

	(Place within any directory, it will need to be referenced in the plist)

    osascript -e 'tell app "Finder" to display dialog "Hello World"'


## Place the following in a new file under ~/Library/LaunchAgents as com.atomicredteam.plist

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
     <key>KeepAlive</key>
     <true/>
     <key>Label</key>
     <string>com.client.client</string>
     <key>ProgramArguments</key>
     <array>
     <string>/Users/<update path to .clent file>/.client</string>
     </array>
     <key>RunAtLoad</key>
     <true/>
     <key>NSUIElement</key>
     <string>1</string>
    </dict>
    </plist>


## Launch:

    launchctl load -w ~/Library/LaunchAgents/com.atomicredteam.plist
