#  Hidden Files and Directories

##  MITRE ATT&CK Technique:
[T1158](https://attack.mitre.org/wiki/Technique/T1158)

##  Input
    sudo xattr -lr * / 2>&1 /dev/null | grep -C 2 "00 00 00 00 00 00 00 00 40 00 FF FF FF FF 00 00"
