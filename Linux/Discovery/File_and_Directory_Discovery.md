#File and Directory Discovery

## MITRE ATT&CK Technique: [T1083](https://attack.mitre.org/wiki/Technique/T1083)

Output a directory tree listing :

    cd $HOME && find . -print | sed -e 's;[^/]*/;|__;g;s;__|; |;g' > /tmp/loot.txt

List Mounted File Systems and Paths

    cat /etc/mtab > /tmp/loot.txt

Find pdfs on a machine

    find . -type f -iname *.pdf > /tmp/loot.txt

Find hidden files on a machine

     find . -type f -name ".*"
