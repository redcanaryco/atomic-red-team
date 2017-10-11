# Component Object Model Hijacking

MITRE ATT&CK Technique: [T1122](https://attack.mitre.org/wiki/Technique/T1122)

## The search order for locating COM Objects can be hijacked, causing unauthorized code to execute.

#### The presence of objects within 

    HKEY_CURRENT_USER\Software\Classes\CLSID\ 

#### May be anomalous and should be investigated since user objects will be loaded prior to machine objects in

    HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\

## Test Script

[COM Hijack Scripts](https://github.com/redcanaryco/atomic-red-team/tree/master/Windows/Payloads/COMHijackScripts)
