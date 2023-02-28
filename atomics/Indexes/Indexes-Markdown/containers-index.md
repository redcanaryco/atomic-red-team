# Containers Atomic Tests by ATT&CK Tactic & Technique
# discovery
- [T1613 Container and Resource Discovery](../../T1613/T1613.md)
  - Atomic Test #1: Container and ResourceDiscovery [containers]
- T1069 Permission Groups Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1046 Network Service Scanning [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# credential-access
- T1110.001 Brute Force: Password Guessing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1552 Unsecured Credentials [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.003 Brute Force: Password Spraying [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1552.001 Unsecured Credentials: Credentials In Files [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1528 Steal Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110 Brute Force [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.004 Brute Force: Credential Stuffing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1552.007 Kubernetes List Secrets](../../T1552.007/T1552.007.md)
  - Atomic Test #1: List All Secrets [containers]
  - Atomic Test #2: ListSecrets [containers]

# persistence
- T1133 External Remote Services [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1053.007 Kubernetes Cronjob](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1525 Implant Internal Image [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Valid Accounts: Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# initial-access
- T1133 External Remote Services [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1190 Exploit Public-Facing Application [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Valid Accounts: Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# execution
- [T1053.007 Kubernetes Cronjob](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1610 Deploy a container](../../T1610/T1610.md)
  - Atomic Test #1: Deploy Docker container [containers]
- [T1609 Kubernetes Exec Into Container](../../T1609/T1609.md)
  - Atomic Test #1: ExecIntoContainer [containers]
  - Atomic Test #2: Docker Exec Into Container [containers]
- T1204 User Execution [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1204.003 Malicious Image [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# privilege-escalation
- [T1053.007 Kubernetes Cronjob](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1611 Escape to Host](../../T1611/T1611.md)
  - Atomic Test #1: Deploy container using nsenter container escape [containers]
  - Atomic Test #2: Mount host filesystem to escape privileged Docker container [containers]
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1068 Exploitation for Privilege Escalation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Valid Accounts: Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# defense-evasion
- T1036.005 Masquerading: Match Legitimate Name or Location [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1562 Impair Defenses [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1036 Masquerading [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550 Use Alternate Authentication Material [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1610 Deploy a container](../../T1610/T1610.md)
  - Atomic Test #1: Deploy Docker container [containers]
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1070 Indicator Removal on Host [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1612 Build Image on Host [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1562.001 Impair Defenses: Disable or Modify Tools [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550.001 Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Valid Accounts: Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# lateral-movement
- T1550 Use Alternate Authentication Material [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550.001 Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# impact
- T1499 Endpoint Denial of Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1496 Resource Hijacking [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1498 Network Denial of Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

