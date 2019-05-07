#Requires -RunAsAdministrator
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False,Position=0)]
  [string]$InstallPath = 'C:\AtomicRedTeam',

  [Parameter(Mandatory=$False,Position=0)]
  [string]$DownloadPath = 'C:\AtomicRedTeam'

 )

function Install-AtomicRedTeam {
<#
    .SYNOPSIS

        This is a simple script to download and install Atomic Red Team Invoke-AtomicRedTeam Powershell Framework.

        Atomic Function: Install-AtomicRedTeam
        Author: Red Canary Research
        License: MIT License
        Required Dependencies: powershell-yaml
        Optional Dependencies: None

    .PARAMETER DownloadPath

    Specifies the desired path to download Atomic Red Team.

    .PARAMETER InstallPath

        Specifies the desired path for where to install Atomic Red Team.

    .EXAMPLE

        Install Atomic Red Team
        PS> Install-AtomicRedTeam.ps1

    .EXAMPLE

        Execute a single test
        $T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
        Invoke-AtomicTest $T1117

    .EXAMPLE

        Informational Stream
        Invoke-AtomicTest $T1117 -InformationAction Continue

    .EXAMPLE

        Verbose Stream
        Invoke-AtomicTest $T1117 -Verbose

    .EXAMPLE

        Debug Stream
        Invoke-AtomicTest $T1117 -Debug

    .EXAMPLE

        What if
        If you would like to see what would happen without running the test
        Invoke-AtomicTest $T1117 -WhatIf

    .EXAMPLE


        To run all tests without confirming them run using the Confirm switch to false

        Invoke-AtomicTest $T1117 -Confirm:$false
        Or you can set your $ConfirmPreference to 'Medium'

        $ConfirmPreference = 'Medium'
        Invoke-AtomicTest $T1117

    .EXAMPLE

      Invoke-AllAtomicTests -GenerateOnly

    .NOTES

    Use the '-Verbose' option to print detailed information.

#>


write-verbose "Directory Creation"

if(!(Test-Path -Path $InstallPath )){
    New-Item -ItemType directory -Path $InstallPath
	write-verbose "Setting Execution Policy to Unrestricted"
	set-executionpolicy Unrestricted

	write-verbose "Setting variables for remote URL and download Path"
	$url = "https://github.com/redcanaryco/atomic-red-team/archive/master.zip"
	$path = "$DownloadPath\master.zip"
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$webClient = new-object System.Net.WebClient
	write-verbose "Beginning download from Github"
	$webClient.DownloadFile( $url, $path )

	write-verbose "Extracting ART to C:\AtomicRedTeam\"
	expand-archive -LiteralPath "$DownloadPath\master.zip" -DestinationPath "$InstallPath"

	write-verbose "Installing NuGet PackageProvider"
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

	write-verbose "Installing powershell-yaml"
	Install-Module -Name powershell-yaml -Force

	write-verbose "Importing invoke-atomicRedTeam module"
	Import-Module "$InstallPath\execution-frameworks\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam.psm1"

	write-verbose "Changing current work directory Invoke-AtomicRedTeam"
	cd "$InstallPath\execution-frameworks\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam\"

	write-verbose "Clearing screen"
	clear

	Write-Host "Installation of Invoke-AtomicRedTeam is complete" -Fore Yellow

}
else
{
	Write-Verbose "Atomic Already exists at $InstallPath"
	exit


}
}
Install-AtomicRedTeam
