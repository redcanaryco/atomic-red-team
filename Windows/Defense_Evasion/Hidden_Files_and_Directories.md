# Hidden Files and Directories

## MITRE ATT&CK Technique: [T1158](https://attack.mitre.org/wiki/Technique/T1158)


## Input:

### Hide a file:

    attrib.exe +h filename.exe

### Mark as hidden, system file and read only:

    attrib.exe +h +s +r evil.dll

### List hidden files:

    dir /a
