# Linux Atomic Tests by ATT&CK Tactic & Technique
# persistence
- [T1156 .bash_profile and .bashrc](./T1156/T1156.md)
  - Atomic Test #1: .bash_profile and .bashrc [macos, linux]
- T1067 Bootkit [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1176 Browser Extensions](./T1176/T1176.md)
  - Atomic Test #1: Chrome (Developer Mode) [linux, windows, macos]
  - Atomic Test #2: Chrome (Chrome Web Store) [linux, windows, macos]
  - Atomic Test #3: Firefox [linux, windows, macos]
- [T1136 Create Account](./T1136/T1136.md)
  - Atomic Test #1: Create a user account on a Linux system [linux]
- [T1158 Hidden Files and Directories](./T1158/T1158.md)
  - Atomic Test #1: Create a hidden file in a hidden directory [linux, macos]
  - Atomic Test #3: Hidden file [macos, linux]
  - Atomic Test #7: Create visible Directories [macos, linux]
  - Atomic Test #8: Create hidden directories and files [macos, linux]
- T1215 Kernel Modules and Extensions [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1168 Local Job Scheduling](./T1168/T1168.md)
  - Atomic Test #1: Cron Job [macos, centos, ubuntu, linux]
  - Atomic Test #2: Cron Job [macos, centos, ubuntu, linux]
- T1205 Port Knocking [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1108 Redundant Access [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1154 Trap](./T1154/T1154.md)
  - Atomic Test #1: Trap [macos, centos, ubuntu, linux]
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1100 Web Shell [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

# discovery
- [T1087 Account Discovery](./T1087/T1087.md)
  - Atomic Test #1: List all accounts [linux, macos]
  - Atomic Test #2: View sudoers access [linux, macos]
  - Atomic Test #3: View accounts with UID 0 [linux, macos]
  - Atomic Test #4: List opened files by user [linux, macos]
  - Atomic Test #5: Show if a user account has ever logger in remotely [linux, macos]
  - Atomic Test #6: Enumerate Groups and users [linux, macos]
- T1217 Browser Bookmark Discovery [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1083 File and Directory Discovery](./T1083/T1083.md)
  - Atomic Test #2: nix file and diectory discovery [macos, linux]
  - Atomic Test #3: nix file and diectory discovery [macos, linux]
- [T1046 Network Service Scanning](./T1046/T1046.md)
  - Atomic Test #1: Scan a bunch of ports to see if they are open [linux, macos]
- T1201 Password Policy Discovery [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1069 Permission Groups Discovery](./T1069/T1069.md)
  - Atomic Test #1: Permission Groups Discovery [macos, linux]
- [T1057 Process Discovery](./T1057/T1057.md)
  - Atomic Test #1: Process Discovery - ps [macos, centos, ubuntu, linux]
- [T1018 Remote System Discovery](./T1018/T1018.md)
  - Atomic Test #4: Remote System Discovery - arp nix [linux, macos]
  - Atomic Test #5: Remote System Discovery - sweep [linux, macos]
- [T1082 System Information Discovery](./T1082/T1082.md)
  - Atomic Test #2: System Information Discovery [linux, macos]
  - Atomic Test #3: List OS Information [linux, macos]
- [T1016 System Network Configuration Discovery](./T1016/T1016.md)
  - Atomic Test #2: System Network Configuration Discovery [macos, linux]
- T1049 System Network Connections Discovery [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1033 System Owner/User Discovery](./T1033/T1033.md)
  - Atomic Test #2: System Owner/User Discovery [linux, macos]

# lateral-movement
- T1017 Application Deployment Software [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1210 Exploitation of Remote Services [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1105 Remote File Copy](./T1105/T1105.md)
  - Atomic Test #1: xxxx [linux, macos]
- T1021 Remote Services [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1184 SSH Hijacking [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1072 Third-party Software [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

# collection
- [T1123 Audio Capture](./T1123/T1123.md)
- [T1119 Automated Collection](./T1119/T1119.md)
- [T1115 Clipboard Data](./T1115/T1115.md)
- [T1074 Data Staged](./T1074/T1074.md)
- T1213 Data from Information Repositories [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1005 Data from Local System [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1039 Data from Network Shared Drive [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1025 Data from Removable Media [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1056 Input Capture](./T1056/T1056.md)
- [T1113 Screen Capture](./T1113/T1113.md)
  - Atomic Test #3: X Windows Capture [linux]
  - Atomic Test #4: Import [linux]

# exfiltration
- T1020 Automated Exfiltration [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1002 Data Compressed](./T1002/T1002.md)
  - Atomic Test #3: Data Compressed - nix [linux, macos]
- [T1022 Data Encrypted](./T1022/T1022.md)
  - Atomic Test #1: Data Encrypted [macos, centos, ubuntu, linux]
- [T1030 Data Transfer Size Limits](./T1030/T1030.md)
  - Atomic Test #1: Data Transfer Size Limits [macos, centos, ubuntu, linux]
- [T1048 Exfiltration Over Alternative Protocol](./T1048/T1048.md)
  - Atomic Test #1: Exfiltration Over Alternative Protocol - SSH [macos, centos, ubuntu, linux]
  - Atomic Test #2: Exfiltration Over Alternative Protocol - SSH [macos, centos, ubuntu, linux]
  - Atomic Test #3: Exfiltration Over Alternative Protocol - HTTP [macos, centos, ubuntu, linux]
- T1041 Exfiltration Over Command and Control Channel [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1011 Exfiltration Over Other Network Medium [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1052 Exfiltration Over Physical Medium [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1029 Scheduled Transfer [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

# credential-access
- [T1139 Bash History](./T1139/T1139.md)
  - Atomic Test #1: xxxx [linux, macos]
- [T1110 Brute Force](./T1110/T1110.md)
- [T1081 Credentials in Files](./T1081/T1081.md)
- T1212 Exploitation for Credential Access [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1056 Input Capture](./T1056/T1056.md)
- T1040 Network Sniffing [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1145 Private Keys](./T1145/T1145.md)
- T1111 Two-Factor Authentication Interception [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

# defense-evasion
- T1009 Binary Padding [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1146 Clear Command History](./T1146/T1146.md)
  - Atomic Test #1: Clear Bash history (rm) [linux, macos]
  - Atomic Test #2: Clear Bash history (echo) [linux, macos]
  - Atomic Test #3: Clear Bash history (cat dev/null) [linux, macos]
  - Atomic Test #4: Clear Bash history (ln dev/null) [linux, macos]
  - Atomic Test #5: Clear Bash history (truncate) [linux]
  - Atomic Test #6: Clear history of a bunch of shells [linux, macos]
- [T1089 Disabling Security Tools](./T1089/T1089.md)
  - Atomic Test #1: Disable iptables firewall [linux]
  - Atomic Test #2: Disable syslog [linux]
  - Atomic Test #3: Disable Cb Response [linux]
  - Atomic Test #4: Disable SELinux [linux]
- T1211 Exploitation for Defense Evasion [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1107 File Deletion](./T1107/T1107.md)
  - Atomic Test #1: Victim configuration [linux]
  - Atomic Test #2: Delete a single file [linux]
  - Atomic Test #3: Delete an entire folder [linux]
  - Atomic Test #4: Overwrite and delete a file with shred [linux]
- [T1148 HISTCONTROL](./T1148/T1148.md)
- [T1158 Hidden Files and Directories](./T1158/T1158.md)
  - Atomic Test #1: Create a hidden file in a hidden directory [linux, macos]
  - Atomic Test #3: Hidden file [macos, linux]
  - Atomic Test #7: Create visible Directories [macos, linux]
  - Atomic Test #8: Create hidden directories and files [macos, linux]
- T1066 Indicator Removal from Tools [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1070 Indicator Removal on Host](./T1070/T1070.md)
  - Atomic Test #3: rm -rf [macos, linux]
- [T1130 Install Root Certificate](./T1130/T1130.md)
  - Atomic Test #1: Install root CA on CentOS/RHEL [linux]
- T1036 Masquerading [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1027 Obfuscated Files or Information [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1205 Port Knocking [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1055 Process Injection](./T1055/T1055.md)
- T1108 Redundant Access [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1014 Rootkit](./T1014/T1014.md)
  - Atomic Test #1: Loadable Kernel Module based Rootkit [linux]
  - Atomic Test #2: Loadable Kernel Module based Rootkit [linux]
  - Atomic Test #3: LD_PRELOAD based Rootkit [linux]
- T1064 Scripting [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1151 Space after Filename](./T1151/T1151.md)
- [T1099 Timestomp](./T1099/T1099.md)
  - Atomic Test #1: Set a file's access timestamp [linux, macos]
  - Atomic Test #2: Set a file's modification timestamp [linux, macos]
  - Atomic Test #3: Set a file's creation timestamp [linux, macos]
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1102 Web Service [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

# execution
- [T1059 Command-Line Interface](./T1059/T1059.md)
  - Atomic Test #1: Command-Line Interface [macos, centos, ubuntu, linux]
- T1203 Exploitation for Client Execution [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1061 Graphical User Interface [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1168 Local Job Scheduling](./T1168/T1168.md)
  - Atomic Test #1: Cron Job [macos, centos, ubuntu, linux]
  - Atomic Test #2: Cron Job [macos, centos, ubuntu, linux]
- T1064 Scripting [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1153 Source [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1151 Space after Filename](./T1151/T1151.md)
- T1072 Third-party Software [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1154 Trap](./T1154/T1154.md)
  - Atomic Test #1: Trap [macos, centos, ubuntu, linux]
- T1204 User Execution [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

# command-and-control
- T1043 Commonly Used Port [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1092 Communication Through Removable Media [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1090 Connection Proxy [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1094 Custom Command and Control Protocol [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1024 Custom Cryptographic Protocol [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1132 Data Encoding [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1001 Data Obfuscation [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1172 Domain Fronting [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1008 Fallback Channels [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1104 Multi-Stage Channels [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1188 Multi-hop Proxy [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1026 Multiband Communication [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1079 Multilayer Encryption [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1205 Port Knocking [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1219 Remote Access Tools [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1105 Remote File Copy](./T1105/T1105.md)
  - Atomic Test #1: xxxx [linux, macos]
- T1071 Standard Application Layer Protocol [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1032 Standard Cryptographic Protocol [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1095 Standard Non-Application Layer Protocol [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1065 Uncommonly Used Port [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1102 Web Service [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

# initial-access
- T1189 Drive-by Compromise [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1190 Exploit Public-Facing Application [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1200 Hardware Additions [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1193 Spearphishing Attachment [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1192 Spearphishing Link [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1194 Spearphishing via Service [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1195 Supply Chain Compromise [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1199 Trusted Relationship [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

# privilege-escalation
- T1068 Exploitation for Privilege Escalation [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- [T1055 Process Injection](./T1055/T1055.md)
- [T1166 Setuid and Setgid](./T1166/T1166.md)
  - Atomic Test #1: Setuid and Setgid [macos, centos, ubuntu, linux]
- T1169 Sudo [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1206 Sudo Caching [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1078 Valid Accounts [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)
- T1100 Web Shell [CONTRIBUTE A TEST](https://atomicredteam.io/contributing)

