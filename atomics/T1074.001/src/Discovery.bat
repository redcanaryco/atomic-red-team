net user Administrator /domain
net Accounts
net localgroup administrators
net use
net share
net group "domain admins" /domain
net config workstation
net accounts
net accounts /domain
net view
sc.exe query
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunServices
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunServices
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify"
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit"
reg query "HKCU\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell"
reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell"
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjectDelayLoad
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnceEx
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run
wmic useraccount list
wmic useraccount get /ALL
wmic startup list brief
wmic share list
wmic service get name,displayname,pathname,startmode
wmic process list brief
wmic process get caption,executablepath,commandline
wmic qfe get description,installedOn /format:csv
arp -a
whoami
ipconfig /displaydns
route print
netsh advfirewall show allprofiles
systeminfo
qwinsta
quser

:: discovery commands found in winpeas post-exploitation tool that was used by Prestige-Ransomware stated by Microsoft blog
:: https://www.microsoft.com/en-us/security/blog/2022/10/14/new-prestige-ransomware-impacts-organizations-in-ukraine-and-poland/

reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\Software\ORL\WinVNC3\Password
reg query HKEY_LOCAL_MACHINE\SOFTWARE\RealVNC\WinVNC4 /v password
reg query HKLM\SYSTEM\CurrentControlSet\Services\SNMP /s
reg query HKCU\Software\TightVNC\Server
reg query HKCU\Software\SimonTatham\PuTTY\Sessions /s
reg query HKCU\Software\OpenSSH\Agent\Keys /s
REG QUERY HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit
REG QUERY HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\EventLog\EventForwarding\SubscriptionManager
REG QUERY "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft Services\AdmPwd" /v AdmPwdEnabled
REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA" /v RunAsPPL
REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\LSA" /v LsaCfgFlags
reg query HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest\UseLogonCredential
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v CACHEDLOGONSCOUNT
REG QUERY HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\ /v EnableLUA
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\1\PowerShellEngine /v PowerShellVersion 
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine /v PowerShellVersion 
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription 
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging 
REG QUERY HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging 
netsh wlan show profiles
dir /s/b /A:-D RDCMan.settings == *.rdg == SCClient.exe == *_history == .sudo_as_admin_successful == .profile == *bashrc == httpd.conf == *.plan == .htpasswd == .git-credentials == *.rhosts == hosts.equiv == Dockerfile == docker-compose.yml == appcmd.exe == TypedURLs == TypedURLsTime == History == Bookmarks == Cookies == "Login Data" == places.sqlite == key3.db == key4.db == credentials == credentials.db == access_tokens.db == accessTokens.json == legacy_credentials == azureProfile.json == unattend.txt == access.log == error.log == *.gpg == *.pgp == *config*.php == elasticsearch.y*ml == kibana.y*ml == *.p12 == *.der == *.csr == *.cer == known_hosts == id_rsa == id_dsa == *.ovpn == anaconda-ks.cfg == hostapd.conf == rsyncd.conf == cesi.conf == supervisord.conf == tomcat-users.xml == *.kdbx == KeePass.config == Ntds.dit == SAM == SYSTEM == FreeSSHDservice.ini == sysprep.inf == sysprep.xml == unattend.xml == unattended.xml == *vnc*.ini == *vnc*.c*nf* == *vnc*.txt == *vnc*.xml == groups.xml == services.xml == scheduledtasks.xml == printers.xml == drives.xml == datasources.xml == php.ini == https.conf == https-xampp.conf == httpd.conf == my.ini == my.cnf == access.log == error.log == server.xml == SiteList.xml == ConsoleHost_history.txt == setupinfo == setupinfo.bak 2>nul 
cd "%SystemDrive%\Users"
dir /s/b .aws == credentials == gcloud == credentials.db == legacy_credentials == access_tokens.db == .azure == accessTokens.json == azureProfile.json 2>nul
cd "%windir%\..\Documents and Settings"
dir /s/b .aws == credentials == gcloud == credentials.db == legacy_credentials == access_tokens.db == .azure == accessTokens.json == azureProfile.json 2>nul
