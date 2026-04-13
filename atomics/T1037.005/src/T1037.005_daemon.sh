#!/bin/sh

. /etc/rc.common

StartService (){

ConsoleMessage "Atomic Test T1037.005 - Daemon"

sudo launchctl load /tmp/T1037_005_daemon.plist

}

StopService (){

return 0

}

RestartService (){

return 0

}

RunService "$1"