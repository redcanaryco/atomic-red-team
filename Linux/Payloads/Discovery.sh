#! /bin/bash
cat /etc/*-release
uname -ar
ifconfig
cat /etc/resolv.conf
df -h
cat /etc/fstab
cat /etc/passwd
cat /etc/group
cat /etc/sudoers
last
yum list installed
chkconfig --list  #works with RHEL/CentOS 6, not 7
systemctl list-unit-files  #works with RHEL/CentOS 7, not 6