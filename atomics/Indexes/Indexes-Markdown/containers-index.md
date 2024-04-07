# Containers Atomic Tests by ATT&CK Tactic & Technique
# initial-access
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1133 External Remote Services [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1190 Exploit Public-Facing Application [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# execution
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1053.007 Kubernetes Cronjob](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1204 User Execution [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1204.003 Malicious Image [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1609 Kubernetes Exec Into Container](../../T1609/T1609.md)
  - Atomic Test #1: ExecIntoContainer [containers]
  - Atomic Test #2: Docker Exec Into Container [containers]
- [T1610 Deploy a container](../../T1610/T1610.md)
  - Atomic Test #1: Deploy Docker container [containers]

# persistence
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1053.007 Kubernetes Cronjob](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1098 Account Manipulation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1098.006 Additional Container Cluster Roles [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1133 External Remote Services [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1136 Create Account [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1136.001 Local Account [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1525 Implant Internal Image [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# privilege-escalation
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1053.007 Kubernetes Cronjob](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1068 Exploitation for Privilege Escalation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1098 Account Manipulation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1098.006 Additional Container Cluster Roles [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1611 Escape to Host](../../T1611/T1611.md)
  - Atomic Test #1: Deploy container using nsenter container escape [containers]
  - Atomic Test #2: Mount host filesystem to escape privileged Docker container [containers]

# defense-evasion
- T1036 Masquerading [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1036.005 Match Legitimate Name or Location [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1070 Indicator Removal [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550 Use Alternate Authentication Material [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550.001 Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1562 Impair Defenses [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1562.001 Disable or Modify Tools [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1610 Deploy a container](../../T1610/T1610.md)
  - Atomic Test #1: Deploy Docker container [containers]
- [T1612 Build Image on Host](../../T1612/T1612.md)
  - Atomic Test #1: Build Image On Host [containers]

# credential-access
- T1110 Brute Force [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.001 Password Guessing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.003 Password Spraying [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.004 Credential Stuffing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1528 Steal Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1552 Unsecured Credentials [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1552.001 Credentials In Files [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1552.007 Kubernetes List Secrets](../../T1552.007/T1552.007.md)
  - Atomic Test #1: List All Secrets [containers]
  - Atomic Test #2: ListSecrets [containers]

# discovery
- [T1046 Network Service Discovery](../../T1046/T1046.md)
  - Atomic Test #9: Network Service Discovery for Containers [containers]
- T1069 Permission Groups Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1613 Container and Resource Discovery](../../T1613/T1613.md)
  - Atomic Test #1: Docker Container and Resource Discovery [containers]
  - Atomic Test #2: Podman Container and Resource Discovery [containers]

# lateral-movement
- T1550 Use Alternate Authentication Material [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550.001 Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# impact
- T1485 Data Destruction [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1490 Inhibit System Recovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1496 Resource Hijacking [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1498 Network Denial of Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1499 Endpoint Denial of Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

