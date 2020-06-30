SETLOCAL EnableDelayedExpansion
del %temp%\1.txt >nul 2>&1 & del %temp%\2.txt >nul 2>&1 & del %temp%\3.txt >nul 2>&1 & del %temp%\users.txt >nul 2>&1
@FOR /F "skip=6 delims=" %%a in ('net users /domain ^| findstr /vc:"The command c"') do @set line=%%a & @call echo %%line:  =,%%  >> %temp%\1.txt
@FOR /F "delims=" %%a in (%temp%\1.txt) do @set line=%%a & @call echo %%line:, =,%% >> %temp%\2.txt
@FOR /F "tokens=1-3 delims=," %%n in (%temp%\2.txt) do @echo %%n >> %temp%\3.txt & @echo %%o >> %temp%\3.txt & @echo %%p >> %temp%\3.txt
@FOR /F "tokens=*" %%a in ('type %temp%\3.txt ^| findstr /vc:"ECHO is on."') do @echo %%a >> %temp%\users.txt