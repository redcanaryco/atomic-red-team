# Defense Evasion

MITRE ATT&CK Technique: [T1146](https://attack.mitre.org/wiki/Technique/T1146)


## multiple shells

    unset HISTFILE

    export HISTFILESIZE=0

    history -c

## bash

    rm ~/.bash_history

	cat /dev/null > ~/.bash_history

	
