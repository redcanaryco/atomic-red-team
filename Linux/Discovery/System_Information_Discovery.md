# System Information Discovery

MITRE ATT&CK Technique: [T1082](https://attack.mitre.org/wiki/Technique/T1082)

List OS information:

    uname -a >> /tmp/loot.txt

List OS specific information:

    cat /etc/lsb-release >> /tmp/loot.txt
    cat /etc/redhat-release >> /tmp/loot.txt

Show how long a machine has been running:

    uptime >> /tmp/loot.txt
