@echo off

rem compiling xbin
cl -nologo -Os xbin.cpp
move /Y xbin.exe ..\bin\xbin.exe

rem x64 version
cl -DWINDOW -D_WIN64 -D_MSC_VER -c -nologo -Os -O2 -Gm- -GR- -EHa -Oi -GS- -w payload.c
link /order:@extrabytes_x64.txt /entry:WndProc /fixed payload.obj -nologo -subsystem:console -nodefaultlib -stack:0x100000,0x100000
..\bin\xbin.exe payload.exe .text

echo "Compiling T1055.011_x64.exe"
cl -DWINDOW -D_WIN64 -D_MSC_VER -nologo -Os -O2 -Gm- -GR- -EHa -Oi -GS- -w ewm.c

ren ewm.exe T1055.011_x64.exe
move /Y T1055.011_x64.exe ..\bin\
move /Y payload.exe64.bin ..\bin\payload.exe_x64.bin

echo "Cleaning files"
del /Q *.obj
del /Q *.exe
