# HISTCONTROL

## MITRE ATT&CK Technique:
	[T1148](https://attack.mitre.org/wiki/Technique/T1148)


## Set the environment variable
    export HISTCONTROL=ignoreboth

OR

    echo export "HISTCONTROL=ignoreboth" >> ~/.bash_profile

## Preface commands with a space to exclude them from .bash_history
    ls
     whoami > recon.txt
