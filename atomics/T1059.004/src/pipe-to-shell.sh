#!/bin/sh

# This script detects when it's being curl downloaded if it is being piped into
# bash. The if switch -t detects a file (descriptor) that is associated with a 
# terminal device. 0 = downloaded 1 = being piped

if [ -t 1 ] 
then 
    echo -e "\nBeing piped\n"
    echo "Atomic Red Team was here... T1059.004" > /tmp/art.txt
else 
    echo -e "\nNOT being piped\n"
fi
