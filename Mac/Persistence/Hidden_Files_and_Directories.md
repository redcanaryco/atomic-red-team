# Hidden Files and Directories

MITRE ATT&CK Technique: [T1158](https://attack.mitre.org/wiki/Technique/T1158)

### Hide files

Input:

    mv filename .filename


Input:

(Requires Apple Dev Tools)

    setfile -a V filename

### Hide Directories

Input:

    chflags hidden /secret/dir

Unhide:

    chflags nohidden



### Show all Hidden

Execute within terminal:

    defaults write com.apple.finder AppleShowAllFiles YES
