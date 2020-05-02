# Atomic Red Team Execution Frameworks
Execution frameworks help you run Atomic Tests in your environment. 
Each atomic test is defined in the [atomics folder](https://github.com/redcanaryco/atomic-red-team/tree/master/execution-frameworks) inside their respective Mitre Att&ck T# folders. 
Within each T# folder you will find a yaml file that defines the commands to be run during the test, and an easier to read markdown (md) version of the same thing.
Here is an [example markdown file](https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1003/T1003.md) describing some of the tests that can be run using one of the below execution frameworks. 

## Invoke-AtomicRedTeam

Invoke-AtomicRedTeam is written in PowerShell, which can be executed cross-platform using PowerShell Core for Linux and MacOS.  
For detailed installation and usage instructions refer to the [README](https://github.com/redcanaryco/invoke-atomicredteam) file. Note that this execution framework exists in a separate GitHub Repository [here](https://github.com/redcanaryco/invoke-atomicredteam).

## Python

Surprise, this framework is written in Python. For detailed installation and usage instructions refer to the [README](https://github.com/redcanaryco/atomic-red-team/tree/master/execution-frameworks/contrib/python) file inside of the **_contrib/python_** folder.

## Ruby

Ruby version of the execution framework.
