## Data Compressed

MITRE ATT&CK Technique: [T1002](https://attack.mitre.org/wiki/Technique/T1002)

### Victim Configuration

    mkdir /tmp/victim-files
    cd /tmp/victim-files
    touch a b c d e f g
    echo "This file will be gzipped" > /tmp/victim-gzip.txt
    echo "This file will be tarred" > /tmp/victim-tar.txt

### Compression with zip

    zip /tmp/victim-files.zip /tmp/victim-files/*

### Compression with gzip

    gzip -f /tmp/victim-gzip.txt

### Compression with tar

Directory

    tar -cvzf /tmp/victim-files.tar.gz /tmp/victim-files/

File

    tar -cvzf /tmp/victim-tar.tar.gz

