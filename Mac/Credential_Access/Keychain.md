# Keychain

MITRE ATT&CK Technique: [T1142](https://attack.mitre.org/wiki/Technique/T1142)

### Keychain Files

    ~/Library/Keychains/

    /Library/Keychains/

    /Network/Library/Keychains/

### security command line

Input:

    security -h

Input:

    security find-certificate -a -p > allcerts.pem

Input:

    security import /tmp/certs.pem -k


### References

[Security Reference](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/security.1.html)

[Keychain dumper](https://github.com/juuso/keychaindump)
