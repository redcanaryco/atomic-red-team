# Account Discovery

MITRE ATT&CK Technique: [T1087](https://attack.mitre.org/wiki/Technique/T1087)

List of all accounts:

    cat /etc/passwd

View sudoers access (requires root):

    cat /etc/sudoers > /tmp/loot.txt

View accounts with UID 0:

    grep 'x:0:' /etc/passwd > /tmp/loot.txt

List opened files by user:

    username=$(echo $HOME | awk -F'/' '{print $3}') && lsof -u $username

Currently logged in:

Local:

    finger

Remote:

    finger @<computer_name>

Show if a user account has ever logged in remotely:

    lastlog > /tmp/loot.txt
