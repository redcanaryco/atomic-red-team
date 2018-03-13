# Disabling Security Tools

MITRE ATT&CK Technique: [T1089](https://attack.mitre.org/wiki/Technique/T1089)


## Stop and disable firewall on CentOS/RHEL 6 and below

    service iptables stop
    chkconfig off iptables

    service ip6tables stop
    chkconfig off ip6tables

## Stop and disable firewall on CentOS/RHEL 7 and above

    systemctl stop firewalld
    systemctl disable firewalld

## Stop and disable syslog on CentOS/RHEL 6 and below
    service rsyslog stop
    chkconfig off rsyslog

## Stop and disable syslog on CentOS/RHEL 7 and above
    systemctl stop rsyslog
    systemctl disable rsyslog

## Stop and disable Cb Response Daemon on CentOS/RHEL 6 and below
    service cbdaemon stop
    chkconfig off cbdaemon

## Stop and disable Cb Response Daemon on CentOS/RHEL 7 and above
    systemctl stop cbdaemon
    systemctl disable cbdaemon

## Disable SELinux Enforcement
    setenforce 0