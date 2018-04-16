## MITRE ATT&CK Matrix - Mac

| Initial Access	| Execution	| Persistence	| Privilege Escalation	| Defense Evasion	| Credential Access	| Discovery	| Lateral Movement	| Collection	| Exfiltration	| Command and Control|
|-------------------------------------------------------|----------------------------------------|-----------------------------------------|----------------------------------------|----------------------------------------|-------------------------------------|------------------------------------|--------------------------------|--------------------------------|-----------------------------------------------|-----------------------------------------|
| Drive-by Compromise	| AppleScript	| bash_profile and .bashrc	| Dylib Hijacking	| Binary Padding	| Bash History	| Account Discovery	| AppleScript	| Audio Capture	| Automated Exfiltration	| Commonly Used Port| 
| Exploit Public-Facing Application	| Command-Line Interface	| Browser Extensions	| Exploitation for Privilege Escalation	| Clear Command History	| Brute Force	| Application Window Discovery	| Application Deployment Software	| Automated Collection	| Data Compressed	| Communication Through Removable Media| 
| Hardware Additions	| Exploitation for Client Execution	| Create Account	| Launch Daemon	|Code Signing	| Credentials in Files	| Browser Bookmark Discovery	| Exploitation of Remote Services	| Clipboard Data	| Data Encrypted	| Connection Proxy| 
| Spearphishing Attachment	| Graphical User Interface	| Dylib Hijacking	| Plist Modification	| Disabling Security Tools	| Exploitation for Credential Access	| File and Directory Discovery	| Logon Scripts	Data | Staged	Data | Transfer Size Limits	| Custom Command and Control Protocol| 
| Spearphishing Link	| Launchctl	| Hidden Files and Directories	| Process Injection	| Exploitation for Defense Evasion	| Input Capture	| Network Service Scanning	| Remote File Copy	| Data from Information Repositories	| Exfiltration Over Alternative Protocol	| Custom Cryptographic Protocol| 
| Spearphishing via Service	| 	Local Job Scheduling	| Kernel Modules and Extensions	| Setuid and Setgid	| File Deletion	| Input Prompt	| Network Share Discovery	| Remote Services	| Data from Local System	| Exfiltration Over Command and Control Channel	| Data Encoding| 
| Supply Chain Compromise	| Scripting	| LC_LOAD_DYLIB Addition	| Startup Items	| Gatekeeper Bypass	| Keychain	| Password Policy Discovery	| SSH Hijacking	| Data from Network Shared Drive	| Exfiltration Over Other Network Medium	| Data Obfuscation| 
| Trusted Relationship	| Source	| Launch Agent	| Sudo	| HISTCONTROL	| Network Sniffing	|Permission Groups Discovery	| Third-party Software	| Data from Removable Media	| Exfiltration Over Physical Medium	| Domain Fronting| 
| Valid Accounts	| Space after Filename	| Launch Daemon	| Sudo Caching	| Hidden Files and Directories	|Private Keys	| Process Discovery| 		| Input Capture	| Scheduled Transfer	| Fallback Channels| 
| 		| Third-party Software	| Launchctl	| Valid Accounts	| Hidden Users	| Securityd Memory	| Remote System Discovery		| 		| Screen Capture		| 			| Multi-Stage Channels| 
| 		| Trap	| Local Job Scheduling	| Web Shell	| Hidden Window	| Two-Factor Authentication Interception	| Security Software Discovery		|		|  Video Capture		| 		| Multi-hop Proxy| 
| 		| User Execution	| Login Item		| 		| Indicator Removal from Tools		| 		| System Information Discovery				| 		| 		| 		| Multiband Communication| 
| 		| 		| Logon Scripts		| 			| Indicator Removal on Host		| 			| System Network Configuration Discovery				| 		| 		| 		| Multilayer Encryption| 
| 		| 		| Plist Modification		| 		| Install Root Certificate		| 		| System Network Connections Discovery				| 		| 		| 		| Port Knocking| 
|  		| 		| Port Knocking		| 		| LC_MAIN Hijacking		| 			| System Owner/User Discovery				| 		| 		| 		| Remote Access Tools| 
|  		| 		| Rc.common		| 		| Launchctl						| 		| 		| 		| 		| 		| Remote File Copy| 
|  		| 		| Re-opened Applications		| 	| Masquerading			| 		| 		| 		| 		| 		| Standard Application Layer Protocol| 
|  		| 		| Redundant Access		| 	| Obfuscated Files or Information		| 		| 		| 		| 		| 		| Standard Cryptographic Protocol| 
|  		| 		| Startup Items		| 	| Plist Modification						| 		| 		| 		| 		| 		| Standard Non-Application Layer Protocol| 
|  		| 		| Trap		| 	| Port Knocking								| 		| 		| 		| 		| 		| Uncommonly Used Port| 
|  		| 		| Valid Accounts		| 		| Process Injection						| 		| 		| 		| 		| 		| Web Service| 
|  		| 		| Web Shell		| 	| Redundant Access			 	| 	| 	| 	| 	| 	| 	| 		
| 	| 	| 	| 	| Rootkit					| 	 	| 	| 	| 	| 	| 	| 			
| 	| 	| 	| 	|  Scripting				| 		| 	| 	| 	| 	| 	| 	 
| 	| 	| 	| 	|  Space after Filename		| 		| 	| 	| 	| 	| 	| 	 		
| 	| 	| 	| 	|  Valid Accounts			| 		| 	| 	| 	| 	| 	| 	 	
| 	| 	| 	| 	|  Web Service				| 	 	| 	| 	| 	| 	| 	| 	  
