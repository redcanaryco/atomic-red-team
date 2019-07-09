# Listeners

Simple methods to simulate C2 server

## Python

python3
`python3 -m http.server 9000`

python2
`python  -m SimpleHTTPServer 9000`


## PowerShell

[PowerShell Webserver](https://gallery.technet.microsoft.com/scriptcenter/Powershell-Webserver-74dcf466)

Start webserver with binding to http://localhost:8080/ (assuming the script is in the current directory):

PowerShell
`.\Start-Webserver.ps1`

Start webserver with binding to all IP addresses of the system and port 8080 (assuming the script is in the current directory).
Administrative rights are necessary:
PowerShell
`.\Start-Webserver.ps1 "http://+:8080/"`
