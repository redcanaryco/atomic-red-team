@echo off
setlocal enableDelayedExpansion

:: The MSBuild-helper. Part of GetNuTool
:: https://github.com/3F/GetNuTool

:: arguments:
::
::      msbuild -notamd64 <args> - to select x86 instance instead of x64 if it's possible.
::      msbuild <args> - to select any available instance.
::

set args=%*
set notamd64=0

set a=%args:~0,30%
set a=%a:"=%

if "%a:~0,9%"=="-notamd64" (
    call :popa %1
    shift
    set notamd64=1
)

for %%v in (14.0, 12.0, 15.0, 4.0, 3.5, 2.0) do (
    for /F "usebackq tokens=2* skip=2" %%a in (
        `reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\%%v" /v MSBuildToolsPath 2^> nul`
    ) do if exist %%b (

        if NOT "%notamd64%" == "1" (
            set msbuild=%%b\msbuild.exe
            goto found
        )

        :: 7z & amd64\msbuild - https://github.com/3F/vsSolutionBuildEvent/issues/38
        set _amd=..\msbuild.exe
        if exist "%%b/!_amd!" (
            set msbuild=%%b\!_amd!
        ) else ( 
            set msbuild=%%b\msbuild.exe
        )
        goto found
    )
)

echo MSBuild was not found, try: ` "full_path_to_msbuild.exe" arguments ` 1>&2
goto exit


:found

set msbuild="%msbuild%"

echo MSBuild Tools: %msbuild% 

%msbuild% %args%

:popa
call set args=%%args:%1^=%%
exit /B 0

:exit
exit /B 0