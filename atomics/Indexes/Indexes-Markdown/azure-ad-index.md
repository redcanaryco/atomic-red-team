# Azure AD Atomic Tests by ATT&CK Tactic & Technique
# credential-access
- [T1110.001 Brute Force: Password Guessing](../../T1110.001/T1110.001.md)
  - Atomic Test #3: Brute Force Credentials of single Azure AD user [azure-ad]
- T1110.002 Brute Force: Password Cracking [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1606.002 Forge Web Credentials: SAML token](../../T1606.002/T1606.002.md)
  - Atomic Test #1: Golden SAML [azure-ad]
- T1552 Unsecured Credentials [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1110.003 Brute Force: Password Spraying](../../T1110.003/T1110.003.md)
  - Atomic Test #4: Password spray all Azure AD users with a single password [azure-ad]
  - Atomic Test #7: Password Spray Microsoft Online Accounts with MSOLSpray (Azure/O365) [azure-ad]
- T1528 Steal Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1606 Forge Web Credentials [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1621 Multi-Factor Authentication Request Generation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110 Brute Force [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.004 Brute Force: Credential Stuffing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# impact
- T1498.001 Direct Network Flood [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1499.003 Application Exhaustion Flood [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1499.004 Application or System Exploitation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1498.002 Reflection Amplification [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1499.002 Service Exhaustion Flood [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1499 Endpoint Denial of Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1498 Network Denial of Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# discovery
- T1069 Permission Groups Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1069.003 Cloud Groups [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1087 Account Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1087.004 Cloud Account [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1518.001 Software Discovery: Security Software Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1526 Cloud Service Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1518 Software Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1538 Cloud Service Dashboard [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# defense-evasion
- [T1484.002 Domain Trust Modification](../../T1484.002/T1484.002.md)
  - Atomic Test #1: Add Federation to Azure AD [azure-ad]
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1108 Redundant Access [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1484 Domain Policy Modification [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.004 Valid Accounts: Cloud Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# privilege-escalation
- [T1484.002 Domain Trust Modification](../../T1484.002/T1484.002.md)
  - Atomic Test #1: Add Federation to Azure AD [azure-ad]
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1484 Domain Policy Modification [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.004 Valid Accounts: Cloud Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# persistence
- T1098.003 Additional Cloud Roles [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1108 Redundant Access [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
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
- T1136 Create Account [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.004 Valid Accounts: Cloud Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# initial-access
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.004 Valid Accounts: Cloud Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

