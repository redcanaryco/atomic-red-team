## MITRE ATT&CK Matrix - Windows

| Initial Access	| Execution	| Persistence	| Privilege Escalation	| Defense Evasion	| Credential Access	| Discovery	| Lateral Movement	| Collection	| Exfiltration	| Command and Control|
|-------------------------------------------------------|----------------------------------------|-----------------------------------------|----------------------------------------|----------------------------------------|-------------------------------------|------------------------------------|--------------------------------|--------------------------------|-----------------------------------------------|-----------------------------------------|
| Drive-by Compromise	| CMSTP	| Accessibility Features	| Access Token Manipulation	| Access Token Manipulation	| Account Manipulation	| Account Discovery	| Application Deployment Software	| Audio Capture	| Automated Exfiltration	| Commonly Used Port |
| Exploit Public-Facing Application	| Command-Line Interface	| AppCert DLLs	| Accessibility Features	| BITS Jobs	| Brute Force	| Application Window Discovery	| Distributed Component Object Model	| Automated Collection	| Data Compressed	| Communication Through Removable Media |
| Hardware Additions	| Control Panel Items	| AppInit DLLs	| AppCert DLLs	| Binary Padding	| Credential Dumping	| Browser Bookmark Discovery	| Exploitation of Remote Services	| Clipboard Data	| Data Encrypted	| Connection Proxy|
| Replication Through Removable Media	| Dynamic Data Exchange	| Application Shimming	| AppInit DLLs	| Bypass User Account Control	| Credentials in Files	| File and Directory Discovery	| Logon Scripts	| Data Staged	| Data Transfer Size Limits	| Custom Command and Control Protocol |
| Spearphishing Attachment	Execution through API	| Authentication Package	| Application Shimming	| CMSTP	| Credentials in Registry	| Network Service Scanning	| Pass the Hash	| Data from Information Repositories	| Exfiltration Over Alternative Protocol	| Custom Cryptographic Protocol |
| Spearphishing Link	| Execution through Module Load	| BITS Jobs	| Bypass User Account Control	| Code Signing	| Exploitation for Credential Access	| Network Share Discovery	| Pass the Ticket	Data from Local System	| Exfiltration Over Command and Control Channel	|Data Encoding |
| Spearphishing via Service	| Exploitation for Client Execution	| Bootkit	|DLL Search Order Hijacking	| Component Firmware	| Forced Authentication	| Password Policy Discovery	| Remote Desktop Protocol	| Data from Network Shared Drive	| Exfiltration Over Other Network Medium	| Data Obfuscation |
| Supply Chain Compromise	| Graphical User Interface	| Browser Extensions	| Exploitation for Privilege Escalation	| Component Object Model Hijacking	| Hooking	| Peripheral Device Discovery	| Remote File Copy	| Data from Removable Media	| Exfiltration Over Physical Medium	| Domain Fronting |
|Trusted Relationship	| InstallUtil	| Change Default File Association	| Extra Window Memory Injection	| Control Panel Items	| Input Capture	| Permission Groups Discovery	| Remote Services	| Email Collection	| Scheduled Transfer	| Fallback Channels |
| Valid Accounts	| LSASS Driver	| Component Firmware	| File System Permissions Weakness	| DCShadow	| Kerberoasting	| Process Discovery	| Replication Through Removable Media	| Input Capture |     |  Multi-Stage Channels |
|      | Mshta	| Component Object Model Hijacking	| Hooking	| DLL Search Order Hijacking	| LLMNR/NBT-NS Poisoning	| Query Registry	| Shared Webroot	| Man in the Browser	|      		| Multi-hop Proxy	|     
|      |PowerShell	| Create Account	| Image File Execution Options Injection	| DLL Side-Loading	| Network Sniffing	| Remote System Discovery	Taint Shared Content	| Screen Capture		|      | Multiband Communication	|  
|      |Regsvcs/Regasm	| DLL Search Order Hijacking	| New Service	| Deobfuscate/Decode Files or Information	| Password Filter DLL	| Security Software Discovery	| Third-party Software	| Video Capture		|      | Multilayer Encryption	|  
|      |Regsvr32	| External Remote Services	| Path Interception	| Disabling Security Tools	| Private Keys	| System Information Discovery	| Windows Admin Shares			| 			| 			| Remote Access Tools		|
|      |Rundll32	| File System Permissions Weakness	| Port Monitors	| Exploitation for Defense Evasion	| Replication Through Removable Media	| System Network Configuration Discovery	| Windows Remote Management			| 			| 			| Remote File Copy			| 			|
|      |Scheduled Task	| Hidden Files and Directories	| Process Injection	| Extra Window Memory Injection	| Two-Factor Authentication Interception	| System Network Connections Discovery				| 			| 			| 			| 			| Standard Application Layer Protocol		| 		
|      | Scripting	| Hooking	| SID-History Injection	| File Deletion		| 			| System Owner/User Discovery				| 			| 			| 			| Standard Cryptographic Protocol|
|      |Service Execution	| Hypervisor	| Scheduled Task	| File System Logical Offsets		| 			| System Service Discovery				| 			| 			| 			| Standard Non-Application Layer Protocol|			
|      |Signed Binary Proxy Execution	| Image File Execution Options Injection	| Service Registry Permissions Weakness	| Hidden Files and Directories		| 			| System Time Discovery				|			| 			| 			|  Uncommonly Used Port|
|      				| Signed Script Proxy Execution	| LSASS Driver	| Valid Accounts	| Image File Execution Options Injection						| 			| 			| 			| 			| 			| Web Service		|
|		| Third-party Software	| Logon Scripts	| Web Shell	| Indicator Blocking								| 				| 		| 		| 			| 			| 			|
| 		| Trusted Developer Utilities	| Modify Existing Service		|	|  Indicator Removal from Tools		|				 | 		|		|		 | 		|		 |
|		| User Execution	| Netsh Helper DLL		|		 | Indicator Removal on Host						| 		 		| 		|		 |		 | 		|		 |
|		|  Windows Management Instrumentation	| New Service		| 		|Indirect Command Execution			|				 | 		|		 |		 |		 | 		|	
| 		| Windows Remote Management	| Office Application Startup		|  		|Install Root Certificate		| 				|		|		 | 		|		 |		 |
|		 | 		| Path Interception		|  		|InstallUtil													| 				|		|		 | 		|		 |		 |
|		 | 		| Port Monitors		|  		|Masquerading								 						| 				|		 |		 | 		|		 |		 |
|		 | 		| Redundant Access		|  		|Modify Registry								    | 			|				 |		 | 		|		 |		 |
|		 | 		| Registry Run Keys / Start Folder		|  		|Mshta								| 			|				 |		 | 		|		 |		 |
|		 | 		| SIP and Trust Provider Hijacking		|  		|NTFS File Attributes				| 			|				 |		 | 		|		 |		 |
|		 | 		| Scheduled Task		|  		|Network Share Connection Removal					| 			|				 |		 | 		|		 |		 |
|		 | 		| Screensaver		|  		|Obfuscated Files or Information				 		| 			|				 |		 | 		|		 |		 |
|		 | 		| Security Support Provider	|  		|	Process Doppelgänging						| 			|				 |		 | 		|		 |		 |
|		 | 		| Service Registry Permissions Weakness	  		|		| Process Hollowing			| 			|				 |		 | 		|		 |		 |
|		 | 		| Shortcut Modification		| 		| Process Injection								| 			|				 |		 | 		|		 |		 |
|		 | 		| System Firmware			| 		| Redundant Access								| 			|				 |		 | 		|		 |		 |
|		 | 		| Time Providers			| 		| Regsvcs/Regasm				 				| 			|				 |		 |		| 		 |		 |
|		 | 		| Valid Accounts			| 		| Regsvr32										| 			|				 |		 | 		|		 |		 |
|		 | 		|  Web Shell				| 		| Rootkit										| 			|				 |		 |		| 		 |		 |
|		 | 		| Windows Management Instrumentation Event Subscription		| 		| Rundll32		| 			|				 |		 |		| 		 |		 |
|		 | 		| Winlogon Helper DLL		| 		| SIP and Trust Provider Hijacking				| 			|				 |		 | 		|		 |		 |
| 		| 		| 							| 		| Scripting										| 			|				 |		 | 		|		 |		 |
| 		| 		| 							| 		| Signed Binary Proxy Execution					| 			|				 |		 | 		|		 |		 |
| 		| 		| 							| 		| Signed Script Proxy Execution				 	| 			|				 |		 | 		|		 |		 |
| 		| 		| 							| 		| Software Packing						 		| 			|				 |		 | 		|		 |		 |
| 		| 		| 							| 		| Timestomp								 		| 			|				 |		 | 		|		 |		 |
| 		| 		| 							| 		| Trusted Developer Utilities			 		| 			|				 |		 | 		|		 |		 |
| 		| 		| 							| 		| Valid Accounts						 		| 			|				 |		 | 		|		 |		 |
| 		| 		| 							| 		| Web Service						 			| 			|				 |		 | 		|		 |		 |
