#!/bin/sh

. /etc/rc.common

StartService (){

ConsoleMessage "Atomic Test T1037.005 - Agent"

launchctl load -w /tmp/T1037_005_agent.plist

}

StopService (){

return 0

}

RestartService (){

return 0

}

RunService "$1"