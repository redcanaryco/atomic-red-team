# File Deletion

## MITRE ATT&CK Technique:
	[T1107](https://attack.mitre.org/wiki/Technique/T1107)

## Victim Configuration

    echo "This file will be shredded" > /tmp/victim-shred.txt
    mkdir /tmp/victim-files
    cd /tmp/victim-files
    touch a b c d e f g

## Delete a single file

    rm -f /tmp/victim-files/a

## Delete an entire folder

    rm -rf /tmp/victim-files

## Overwrite and delete a file with shred

    shred -u /tmp/victim-shred.txt
