# Containers Atomic Tests by ATT&CK Tactic & Technique
# discovery
- [T1613 Container and Resource Discovery](../../T1613/T1613.md)
  - Atomic Test #1: Docker Container and Resource Discovery [containers]
  - Atomic Test #2: Podman Container and Resource Discovery [containers]
- T1069 Permission Groups Discovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1046 Network Service Discovery](../../T1046/T1046.md)
  - Atomic Test #9: Network Service Discovery for Containers [containers]

# credential-access
- T1110.001 Brute Force: Password Guessing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1552 Unsecured Credentials [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.003 Brute Force: Password Spraying [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1552.001 Unsecured Credentials: Credentials In Files [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1528 Steal Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110 Brute Force [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1110.004 Brute Force: Credential Stuffing [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1552.007 Unsecured Credentials: Container API](../../T1552.007/T1552.007.md)
  - Atomic Test #1: List All Secrets [containers]
  - Atomic Test #2: ListSecrets [containers]

# persistence
- T1543 Create or Modify System Process [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1133 External Remote Services [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1053.007 Scheduled Task/Job: Container Orchestration Job](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1098.006 Additional Container Cluster Roles [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1525 Implant Internal Image [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1136.001 Create Account: Local Account](../../T1136.001/T1136.001.md)
  - Atomic Test #10: Create a Linux user via kubectl in a Pod [containers]
- T1098 Account Manipulation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1543.005 Container Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1136 Create Account [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Valid Accounts: Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# privilege-escalation
- T1543 Create or Modify System Process [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1053.007 Scheduled Task/Job: Container Orchestration Job](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1098.006 Additional Container Cluster Roles [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1611 Escape to Host](../../T1611/T1611.md)
  - Atomic Test #1: Deploy container using nsenter container escape [containers]
  - Atomic Test #2: Mount host filesystem to escape privileged Docker container [containers]
  - Atomic Test #3: Privilege Escalation via Docker Volume Mapping [containers]
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1098 Account Manipulation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1543.005 Container Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1068 Exploitation for Privilege Escalation [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Valid Accounts: Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# initial-access
- T1133 External Remote Services [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1190 Exploit Public-Facing Application [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Valid Accounts: Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# execution
- [T1053.007 Scheduled Task/Job: Container Orchestration Job](../../T1053.007/T1053.007.md)
  - Atomic Test #1: ListCronjobs [containers]
  - Atomic Test #2: CreateCronjob [containers]
- T1053 Scheduled Task/Job [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1610 Deploy Container](../../T1610/T1610.md)
  - Atomic Test #1: Deploy Docker container [containers]
- T1059 Command and Scripting Interpreter [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1609 Container Administration Command](../../T1609/T1609.md)
  - Atomic Test #1: ExecIntoContainer [containers]
  - Atomic Test #2: Docker Exec Into Container [containers]
- T1204 User Execution [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1204.003 User Execution: Malicious Image [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1059.013 Container CLI/API [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# stealth
- T1036.005 Masquerading: Match Legitimate Resource Name or Location [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1036 Masquerading [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.001 Valid Accounts: Default Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1070 Indicator Removal [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- [T1612 Build Image on Host](../../T1612/T1612.md)
  - Atomic Test #1: Build Image On Host [containers]
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1036.010 Masquerade Account Name [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1078.003 Valid Accounts: Local Accounts [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# lateral-movement
- T1550 Use Alternate Authentication Material [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1550.001 Application Access Token [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# impact
- T1496.002 Bandwidth Hijacking [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1496.001 Compute Hijacking [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1499 Endpoint Denial of Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1496 Resource Hijacking [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1485 Data Destruction [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1498 Network Denial of Service [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)
- T1490 Inhibit System Recovery [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

# defense-impairment
- T1685 Disable or Modify Tools [CONTRIBUTE A TEST](https://github.com/redcanaryco/atomic-red-team/wiki/Contributing)

