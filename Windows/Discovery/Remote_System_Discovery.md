# Remote System Discovery

MITRE ATT&CK Technique: [T1018](https://attack.mitre.org/wiki/Technique/T1018)

### net.exe

    net view /domain

    net view

### Ping

Ping Sweep:

    for /l %i in (1,1,254) do ping -n 1 -w 100 192.168.1.%i

### ARP

    arp -a
