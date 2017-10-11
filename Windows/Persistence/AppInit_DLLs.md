## AppInit DLLs

MITRE ATT&CK Technique: [T1103](https://attack.mitre.org/wiki/Technique/T1103)

#### AppInit_DLLs is a mechanism that allows an arbitrary list of DLLs to be loaded into each user mode process on the system:
    HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Windows
    
#### LoadAppInit_DLLs (REG_DWORD)	Globally enables or disables AppInit_DLLs.

    0x0 – AppInit_DLLs are disabled.
    
    0x1 – AppInit_DLLs are enabled.
    
#### AppInit_DLLs (REG_SZ)	Space or comma delimited list of DLLs to load. The complete path to the DLL should be specified using Short Names.

    C:\ PROGRA~1\WID288~1\MICROS~1.DLL

##### RequireSignedAppInit_DLLs (REG_DWORD)	Only load code-signed DLLs.	0x0 – Load any DLLs.

    0x1 – Load only code-signed DLLs.    

## Test Script

[AppInitInject.reg](https://github.com/redcanaryco/atomic-red-team/blob/master/Windows/Payloads/AppInitInject.reg)
