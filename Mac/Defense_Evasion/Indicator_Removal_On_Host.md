# Indicator Removal on Host

## MITRE ATT&CK Technique:  
[T1070](https://attack.mitre.org/wiki/Technique/T1070)

## Delete System Logs
    rm -rf /private/var/log/system.log*

## Delete BSM Audit Logs
    rm -rf /private/var/audit/*
