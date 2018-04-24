# Network Share Discovery

## MITRE ATT&CK Technique:
[T1135](https://attack.mitre.org/wiki/Technique/T1135)

## Local Mounts

### Input:

    df -aH

### Remote Find Mounts

   smbutil view -g //<hostname>


### NFS Show mounts

    showmount hostname
