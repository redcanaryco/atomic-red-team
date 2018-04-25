# Application Shimming

## MITRE ATT&CK Technique:
[T1138](https://attack.mitre.org/wiki/Technique/T1138)

## Deploying a custom shim database to users requires the following actions:

### 1.) Placing the custom shim database (*.sdb file) in a location to which the user’s computer has access (either locally or on the network)

### 2.) Possibly calling the sdbinst.exe command-line utility to install the custom shim database locally.

### 3.) Registry Modification - This is completed either manually or by an installation tool.

    HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Custom

    HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\InstalledSDB

#### Detecting the shim execution is difficult. We suggest detection of Shim Installation.

## Test Script

[AppCompatShims](https://github.com/redcanaryco/atomic-red-team/blob/master/Windows/Payloads/AppCompatShims)
