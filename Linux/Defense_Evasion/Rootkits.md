# Rootkits

## MITRE ATT&CK Technique:
	[T1014](https://attack.mitre.org/wiki/Technique/T1014)

## Loadable Kernel Module based Rootkit

Input:

    sudo insmod MODULE.ko

OR

Input:

    sudo modprobe MODULE.ko

## LD_PRELOAD based Rootkit

Input:

    export LD_PRELOAD=$PWD/libmy_r00tkit.so
