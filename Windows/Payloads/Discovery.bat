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
wmic useraccount list
wmic useraccount get /ALL
wmic startup list brief
wmic share list
wmic service get name,displayname,pathname,startmode
wmic process list brief
wmic process get caption,executablepath,commandline
wmic qfe get description,installedOn /format:csv
arp -a
"cmd.exe" /C whoami
ipconfig /displaydns
route print
netsh advfirewall show allprofiles
systeminfo
qwinsta
quser
