#  Data Encrypted

##  MITRE ATT&CK Technique:
[T1022](https://attack.mitre.org/wiki/Technique/T1022)

##  Victim Configuration
    echo "This file will be encrypted" > /tmp/victim-gpg.txt
    mkdir /tmp/victim-files
    cd /tmp/victim-files
    touch a b c d e f g

##  Zip and encrypt a directory
    zip --password "insert password here" /tmp/victim-files.zip /tmp/victim-files/*

##  Encrypt a single file
    gpg -c /tmp/victim-gpg.txt
    <enter passphrase and confirm>
    ls -l
