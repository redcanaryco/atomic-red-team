single test

Right now single test will do the following:
T1166 copy script to /tmp and setuid and run
T1156 add command to .bashrc
T1113 capture screen (possible usage: combine with T1156, can be done but for now there is no reason to do it)
T1022 encrypt data (can be done with T1139 or T1113 so user will not be able to find what happened)
T1090 set up connection proxy (can monitor the network traffic)
T1059 download shell script from the web and execute without notify the user
T1139 copy credential bash history to another file
T1146 clear all bash history

problems: Hash, writing functions to interact
