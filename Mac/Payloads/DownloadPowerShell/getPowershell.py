# Simple script to download PowerShell from Github and then extract, make, install, and run.
# Then output 'Hello World' in PowerShell


import requests
import tarfile
import os
import pexpect

# Grabs the current user for saving to user defined directories
currentuser = os.getlogin()

# Such as the User's Downloads directory on MacOS
savedirectory = '/Users/' + currentuser + '/Downloads/powershell.tar.gz'

url = 'https://github.com/PowerShell/PowerShell/releases/download/v6.0.1/powershell-6.0.1-osx-x64.tar.gz'
response = requests.get(url)

# Downloads and saves the file to directory
with open(savedirectory, 'wb') as f:
    f.write(response.content)

print("Successfully saved file to " + savedirectory)
print("Extracting file now")

# Sets up where to extract the tar file
tarpath = '/Users/' + currentuser + '/Downloads/powershell/'

with tarfile.open(savedirectory) as tar:
    tar.extractall(path=tarpath)

psexec = tarpath + 'pwsh'
print(psexec)

# On Mac the file pwsh is a shell script to run PowerShell.
# This essentially does chmod +x to run pwsh
print("Changing permissions on powershell executable")
os.chmod(psexec, 0o755)

# Using pexpect to run an interactive session of PowerShell
with open('log', 'ab') as fout:
    p = pexpect.spawn(psexec)
    p.logfile = fout
    p.interact()



