# Credentials in Files

MITRE ATT&CK Technique: [T1081](https://attack.mitre.org/wiki/Technique/T1081)

## Group Policy Preference

[Payload](Payloads/Get-GPPPassword.ps1)
[PowerSploit Source](https://github.com/PowerShellMafia/PowerSploit/blob/master/Exfiltration/Get-GPPPassword.ps1)

Input:

    Get-GPPPassword -Server EXAMPLE.COM
    
## Manually Enumertae XML Files From SYSVOL:

From the mounted SYSVOL share:

    `dir -s *.xml`
