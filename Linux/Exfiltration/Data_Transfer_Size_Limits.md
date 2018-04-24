# Data Transfer Size Limits

## MITRE ATT&CK Technique:
[T1030](https://attack.mitre.org/wiki/Technique/T1030)

## Victim Configuration

    cd /tmp/
    dd if=/dev/urandom of=/tmp/victim-whole-file bs=25M count=1

## Split into 5MB chunks

    split -b 5000000 /tmp/victim-whole-file
    ls -l
