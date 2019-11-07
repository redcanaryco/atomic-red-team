# Atomic Red Team Execution Frameworks
This repository contains execution frameworks that help you run Atomic Tests in your environment. 
The atomic tests are each defined in the [atomics folder](https://github.com/redcanaryco/atomic-red-team/tree/master/execution-frameworks) inside their respective Mitre Att&ck T# folders. 
Within each T# folder you will find a yaml file that defines the commands to be run during the test and an easier to read markdown (md) version showing the test details.
Here is an [example markdown file](https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1003/T1003.md) describing some of the tests that can be run using one of the below execution frameworks. 

## Invoke-AtomicRedTeam

Invoke-AtomicRedTeam is written in PowerShell which can be used cross-platform but currently only supports the **_powershell_** and **_command_prompt_** executors (Windows stuff). 
For detailed installation and usage instructions refer to the [README](https://github.com/redcanaryco/atomic-red-team/tree/master/execution-frameworks/Invoke-AtomicRedTeam) file inside of the **_Invoke-AtomicRedTeam_** folder.

## Python

Surprise, this framework is written in Python. For detailed installation and usage instructions refer to the [README](https://github.com/redcanaryco/atomic-red-team/tree/master/execution-frameworks/contrib/python) file inside of the **_contrib/python_** folder.

## Ruby

Ruby version of the execution framework.