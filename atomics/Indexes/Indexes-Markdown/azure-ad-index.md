# Azure AD Atomic Tests by ATT&CK Tactic & Technique
# credential-access
- [T1110.001 Brute Force: Password Guessing](../../T1110.001/T1110.001.md)
  - Atomic Test #3: Brute Force Credentials of single Azure AD user [azure-ad]
- T1110.002 Brute Force: Password Cracking [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1606.002 Forge Web Credentials: SAML token](../../T1606.002/T1606.002.md)
  - Atomic Test #1: Golden SAML [azure-ad]
- T1552 Unsecured Credentials [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556.007 Hybrid Identity [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1110.003 Brute Force: Password Spraying](../../T1110.003/T1110.003.md)
  - Atomic Test #4: Password spray all Azure AD users with a single password [azure-ad]
  - Atomic Test #7: Password Spray Microsoft Online Accounts with MSOLSpray (Azure/O365) [azure-ad]
- T1649 Steal or Forge Authentication Certificates [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1528 Steal Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1606 Forge Web Credentials [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1621 Multi-Factor Authentication Request Generation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1212 Exploitation for Credential Access [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110 Brute Force [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.004 Brute Force: Credential Stuffing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556.006 Multi-Factor Authentication [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556.009 Conditional Access Policies [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556 Modify Authentication Process [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# discovery
- T1069 Permission Groups Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1069.003 Cloud Groups [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1087 Account Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1087.004 Cloud Account [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1201 Password Policy Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1526 Cloud Service Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1538 Cloud Service Dashboard [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# defense-evasion
- [T1484.002 Domain Trust Modification](../../T1484.002/T1484.002.md)
  - Atomic Test #1: Add Federation to Azure AD [azure-ad]
- T1562 Impair Defenses [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550 Use Alternate Authentication Material [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556.007 Hybrid Identity [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1548 Abuse Elevation Control Mechanism [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1548.005 Temporary Elevated Cloud Access [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556.006 Multi-Factor Authentication [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1562.008 Impair Defenses: Disable Cloud Logs [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556.009 Conditional Access Policies [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1036.010 Masquerade Account Name [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1484 Domain or Tenant Policy Modification [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550.001 Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.004 Valid Accounts: Cloud Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556 Modify Authentication Process [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# privilege-escalation
- [T1484.002 Domain Trust Modification](../../T1484.002/T1484.002.md)
  - Atomic Test #1: Add Federation to Azure AD [azure-ad]
- [T1098.003 Account Manipulation: Additional Cloud Roles](../../T1098.003/T1098.003.md)
  - Atomic Test #1: Azure AD - Add Company Administrator Role to a user [azure-ad]
  - Atomic Test #2: Simulate - Post BEC persistence via user password reset followed by user added to company administrator role [azure-ad]
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1548 Abuse Elevation Control Mechanism [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1548.005 Temporary Elevated Cloud Access [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1098.005 Device Registration [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1098.001 Account Manipulation: Additional Cloud Credentials](../../T1098.001/T1098.001.md)
  - Atomic Test #1: Azure AD Application Hijacking - Service Principal [azure-ad]
  - Atomic Test #2: Azure AD Application Hijacking - App Registration [azure-ad]
- [T1098 Account Manipulation](../../T1098/T1098.md)
  - Atomic Test #4: Azure AD - adding user to Azure AD role [azure-ad]
  - Atomic Test #5: Azure AD - adding service principal to Azure AD role [azure-ad]
  - Atomic Test #8: Azure AD - adding permission to application [azure-ad]
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1484 Domain or Tenant Policy Modification [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.004 Valid Accounts: Cloud Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# initial-access
- T1566.002 Phishing: Spearphishing Link [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1199 Trusted Relationship [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1566 Phishing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1566.004 Spearphishing Voice [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1189 Drive-by Compromise [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.004 Valid Accounts: Cloud Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# persistence
- [T1098.003 Account Manipulation: Additional Cloud Roles](../../T1098.003/T1098.003.md)
  - Atomic Test #1: Azure AD - Add Company Administrator Role to a user [azure-ad]
  - Atomic Test #2: Simulate - Post BEC persistence via user password reset followed by user added to company administrator role [azure-ad]
- T1556.007 Hybrid Identity [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1098.005 Device Registration [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1098.001 Account Manipulation: Additional Cloud Credentials](../../T1098.001/T1098.001.md)
  - Atomic Test #1: Azure AD Application Hijacking - Service Principal [azure-ad]
  - Atomic Test #2: Azure AD Application Hijacking - App Registration [azure-ad]
- [T1136.003 Create Account: Cloud Account](../../T1136.003/T1136.003.md)
  - Atomic Test #2: Azure AD - Create a new user [azure-ad]
  - Atomic Test #3: Azure AD - Create a new user via Azure CLI [azure-ad]
- [T1098 Account Manipulation](../../T1098/T1098.md)
  - Atomic Test #4: Azure AD - adding user to Azure AD role [azure-ad]
  - Atomic Test #5: Azure AD - adding service principal to Azure AD role [azure-ad]
  - Atomic Test #8: Azure AD - adding permission to application [azure-ad]
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556.006 Multi-Factor Authentication [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556.009 Conditional Access Policies [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1136 Create Account [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.004 Valid Accounts: Cloud Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1556 Modify Authentication Process [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# lateral-movement
- T1550 Use Alternate Authentication Material [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1021.007 Cloud Services [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550.001 Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# execution
- T1059.009 Cloud API [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1059 Command and Scripting Interpreter [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

