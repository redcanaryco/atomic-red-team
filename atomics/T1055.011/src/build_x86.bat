@echo off

rem compiling xbin
cl -nologo -Os xbin.cpp
move /Y xbin.exe ..\bin\xbin.exe

rem x86 version
cl -DWINDOW -c -nologo -Os -O2 -Gm- -GR- -EHa -Oi -GS- -w payload.c
link /order:@extrabytes_x86.txt /entry:WndProc /base:0 payload.obj -nologo -subsystem:console -nodefaultlib -stack:0x100000,0x100000
..\bin\xbin.exe payload.exe .text

echo "Compiling T1055.011_x86.exe"
cl -DWINDOW -nologo -Os -O2 -Gm- -GR- -EHa -Oi -GS- -w ewm.c

ren ewm.exe T1055.011_x86.exe
move /Y T1055.011_x86.exe ..\bin\
move /Y payload.exe32.bin ..\bin\payload.exe_x86.bin

echo "Cleaning files"
del /Q *.obj
del /Q *.exe
