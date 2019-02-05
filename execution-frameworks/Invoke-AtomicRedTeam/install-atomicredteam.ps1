#Requires -RunAsAdministrator

function Install-AtomicRedTeam {
<#
    .SYNOPSIS

        Atomic Function: Install-AtomicRedTeam
        Author: Red Canary Research Team
        License: BSD 3-Clause
        Required Dependencies: powershell-Yaml
        Optional Dependencies: None
        
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

        [System.Collections.HashTable]$AllAtomicTests = @{}
        $AtomicFilePath = 'C:\AtomicRedTeam\atomics\'
        Get-ChildItem $AtomicFilePath -Recurse -Filter *.yaml -File | ForEach-Object {
            $currentTechnique = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
            $parsedYaml = (ConvertFrom-Yaml (Get-Content $_.FullName -Raw ))
            $AllAtomicTests.Add($currentTechnique, $parsedYaml);
        }
        $AllAtomicTests.GetEnumerator() | Foreach-Object { Invoke-AtomicTest $_.Value -GenerateOnly }

    .NOTES

    Use the '-Verbose' option to print detailed information.

#>


write-verbose "Directory Creation"

mkdir c:\AtomicRedTeam\

write-verbose "Setting Execution Policy to Unrestricted"
set-executionpolicy Unrestricted

write-verbose "Setting variables for remote URL and download Path"
$url = "https://github.com/redcanaryco/atomic-red-team/archive/master.zip"
$path = "C:\AtomicRedTeam\master.zip"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$webClient = new-object System.Net.WebClient
write-verbose "Beginning download from Github"
$webClient.DownloadFile( $url, $path )

write-verbose "Extracting ART to C:\AtomicRedTeam\"
expand-archive -LiteralPath c:\atomicRedTeam\master.zip -DestinationPath C:\AtomicRedTeam\

write-verbose "Installing NuGet PackageProvider"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

write-verbose "Installing powershell-yaml"
Install-Module -Name powershell-yaml

write-verbose "Importing invoke-atomicRedTeam module"
Import-Module C:\AtomicRedTeam\atomic-red-team-master\execution-frameworks\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam.psm1

write-verbose "Changing current work directory Invoke-AtomicRedTeam"
cd C:\AtomicRedTeam\atomic-red-team-master\execution-frameworks\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam\

write-verbose "Clearing screen"
clear

Write-Host "Installation of Invoke-AtomicRedTeam is complete" -Fore Yellow
}
Install-AtomicRedTeam
