## How to contribute to Atomic Red Team

#### **Atomic Contribution**

Atomic Red Team welcomes all types of contributions as long as it is mapped to [MITRE ATT&CK](https://attack.mitre.org/wiki/Main_Page).

The Framework is also meant to be "easy". If your Atomic test is complicated and requires multiple external utilities/packages/Kali, we may dismiss it.

TEST YOUR Atomic Test! Be sure to run it from a few OS platforms before submitting a pull to ensure everything is working correctly.

If sourcing from another tool/product (ex. generated command), be sure to cite it in your .md file.

Any and all Payloads need to be placed in the respective Windows|Mac|Linux Payload directory.

Be sure you update the ATT&CK url, Txxxx number, and the title (ex. InstallUtil).


#### Atomic Template Example


    ## InstallUtil

    MITRE ATT&CK Technique: [T1118](https://attack.mitre.org/wiki/Technique/T1118)

    ### Execution Examples:

    Input:

        x86 - C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /logfile= /LogToConsole=false /U AllTheThings.dll

        x64 - C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe /logfile= /LogToConsole=false /U AllTheThings.dll

    ## Test Script

    [InstallUtilBypass.cs](https://github.com/redcanaryco/atomic-red-team/blob/master/Windows/Payloads/InstallUtilBypass.cs)
