# System Network Configuration Discovery

#  MITRE ATT&CK Technique:
	[T1016](https://attack.mitre.org/wiki/Technique/T1016)

# Network Data

##  Input:
    arp -a
##  Input:
    netstat -ant | awk '{print $NF}' | grep -v '[a-z]' | sort | uniq -c
##  Input:
    ifconfig
