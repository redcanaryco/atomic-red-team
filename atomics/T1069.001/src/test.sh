#!/bin/sh
if [ -x "$(command -v groups)" ]; then groups; else echo "groups is missing from the machine. skipping..."; fi;
if [ -x "$(command -v id)" ]; then id; else echo "id is missing from the machine. skipping..."; fi;
if [ -x "$(command -v getent)" ]; then getent group; else echo "getent is missing from the machine. skipping..."; fi;
cat /etc/group
