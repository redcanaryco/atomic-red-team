#!/bin/bash

# Find the IP address of the host machine
HOST_IP=$(hostname -I | awk '{print $1}')
echo "Running ifconfig"
ifconfig
echo "Running nmap scan on ${HOST_IP}:"
nmap -sV -O ${HOST_IP}
echo "Running tcpdump -i on ${HOST_IP}:"
tcpdump -i ${HOST_IP} -c 30
echo "Running ss -tlwn on ${HOST_IP}:"
ss -tuwx
