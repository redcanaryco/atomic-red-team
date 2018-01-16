# File Deletion

MITRE ATT&CK Technique: [T1107](https://attack.mitre.org/wiki/Technique/T1107)

## cmd

    del /f filename
    rmdir example

## PowerShell

    Remove-Item –path c:\testfolder –recurse

## vssadmin

    vssadmin.exe Delete Shadows /All /Quiet


## wmic

    wmic shadowcopy delete

## bcdedit

    bcdedit /set {default} bootstatuspolicy ignoreallfailures

    bcdedit /set {default} recoveryenabled no

## wbadmin

    wbadmin delete catalog -quiet
