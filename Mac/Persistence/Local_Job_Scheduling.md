# Local Job Scheduling

MITRE ATT&CK Technique: [T1168](https://attack.mitre.org/wiki/Technique/T1168)

### Cron Job

    echo "* * * * * /tmp/evil.sh" > /tmp/persistevil && crontab /tmp/persistevil

### Emond

Place this file in /etc/emond.d/rules/atomicredteam.plist

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <array>
        <dict>
            <key>name</key>
            <string>atomicredteam</string>
            <key>enabled</key>
            <true/>
            <key>eventTypes</key>
            <array>
                <string>startup</string>
            </array>
            <key>actions</key>
            <array>
                <dict>
                    <key>command</key>
                    <string>/usr/bin/say</string>
                    <key>user</key>
                    <string>root</string>
                    <key>arguments</key>
                        <array>
                            <string>-v Tessa</string>
                            <string>I am a persistent startup item.</string>
                        </array>
                    <key>type</key>
                    <string>RunCommand</string>
                </dict>
            </array>
        </dict>
    </array>
    </plist>

Place an empty file in /private/var/db/emondClients/

    sudo touch /private/var/db/emondClients/randomflag

