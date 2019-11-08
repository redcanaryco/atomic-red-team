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

    .NOTES

    Use the '-Verbose' option to print detailed information.

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 0)]
        [string]$InstallPath = 'C:\AtomicRedTeam',

        [Parameter(Mandatory = $False, Position = 0)]
        [string]$DownloadPath = 'C:\AtomicRedTeam'

    )

    Write-Verbose "Checking if we are Admin"
    $isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isElevated) { Write-Error "This script must be run as an administrator."; exit}


    if (!(Test-Path -Path $InstallPath )) {
        write-verbose "Directory Creation"
        New-Item -ItemType directory -Path $InstallPath | Out-Null
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
        Import-Module "$InstallPath\atomic-red-team-master\execution-frameworks\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam.psm1"

        write-verbose "Changing current work directory Invoke-AtomicRedTeam"
        cd "$InstallPath\atomic-red-team-master\execution-frameworks\Invoke-AtomicRedTeam\"

        write-verbose "Clearing screen"
        clear

        Write-Host "Installation of Invoke-AtomicRedTeam is complete" -Fore Yellow

    }
    else {
        Write-Host "Atomic Redteam already exists at $InstallPath. Importing existing Invoke-atomicRedTeam module"
        cd "$InstallPath\atomic-red-team-master\execution-frameworks\Invoke-AtomicRedTeam\"
        Import-Module "$InstallPath\atomic-red-team-master\execution-frameworks\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam.psm1" -Force

    }
}