## Query Registry

MITRE ATT&CK Technique: [T1012](https://attack.mitre.org/wiki/Technique/T1012)


    reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"
    reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce
    reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce
    reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunServices
    reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunServices
    reg query HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify
    reg query HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit
    reg query HKCU\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\\Shell
    reg query HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\\Shell
    reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ShellServiceObjectDelayLoad
    reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce
    reg query HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnceEx
    reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run
    reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run
    reg query HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce
    reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run
    reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run

Use the following command (as Administrator) to view the drivers configured to load during startup:

    reg query hklm\system\currentcontrolset\services /s | findstr ImagePath 2>nul | findstr /Ri ".*\.sys$"

    Reg Query HKLM\Software\Microsoft\Windows\CurrentVersion\Run

References:

https://blog.cylance.com/windows-registry-persistence-part-2-the-run-keys-and-search-order

https://blog.cylance.com/windows-registry-persistence-part-1-introduction-attack-phases-and-windows-services



    reg save HKLM\Security security.hive (Save security hive to a file)
    reg save HKLM\System system.hive (Save system hive to a file)
    reg save HKLM\SAM sam.hive (Save sam to a file)=
    reg add [\\TargetIPaddr\] [RegDomain][ \Key ]
    reg export [RegDomain]\[Key] [FileName]
    reg import [FileName ]
    reg query [\\TargetIPaddr\] [RegDomain]\[ Key ] /v [Valuename!] (you can to add /s for recurse all values )

References:

http://www.handgrep.se/repository/cheatsheets/postexploitation/WindowsPost-Exploitation.pdf

https://www.offensive-security.com/wp-content/uploads/2015/04/wp.Registry_Quick_Find_Chart.en_us.pdf
