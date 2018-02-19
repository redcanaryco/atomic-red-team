# Setuid and Setgid

MITRE ATT&CK Technique: [T1166](https://attack.mitre.org/wiki/Technique/T1166)

Navigate to [hello.c](../Payloads/hello.c)

Input:

    make hello

    sudo chown root hello

    sudo chmod u+s hello

    ./hello