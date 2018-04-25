# Dynamic Data Exchange

## MITRE ATT&CK Technique:
[T1173](https://attack.mitre.org/wiki/Technique/T1173)


### Microsoft Word

Open,

Insert tab -> Quick Parts -> Field

Choose = (Formula) and click ok.

After that, you should see a Field inserted in the document with an error “!Unexpected End of Formula”, right-click the Field, and choose Toggle Field Codes.

The Field Code should now be displayed, change it to Contain the following:


    {DDEAUTO c:\\windows\\system32\\cmd.exe "/k calc.exe"  }
