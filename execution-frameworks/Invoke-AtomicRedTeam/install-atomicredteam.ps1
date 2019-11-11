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

    .PARAMETER Force

        Delete the existing InstallPath before installation if it exists.

    .EXAMPLE

        Install Atomic Red Team
        PS> Install-AtomicRedTeam.ps1

    .NOTES

    Use the '-Verbose' option to print detailed information.

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 0)]
        [string]$InstallPath = $( if ($IsLinux -or $IsMacOS) { $Env:HOME + "/AtomicRedTeam" } else { $env:HOMEDRIVE + "\AtomicRedTeam" }),

        [Parameter(Mandatory = $False, Position = 1)]
        [string]$DownloadPath = $( if ($IsLinux -or $IsMacOS) { $Env:HOME + "/AtomicRedTeam" } else { $env:HOMEDRIVE + "\AtomicRedTeam" }),

        [Parameter(Mandatory = $False)]
        [switch]$Force = $False # delete the existing install directory and reinstall
    )

    Write-Verbose "Checking if we are Admin"
    $isElevated = $false
    if ($IsLinux -or $IsMacOS) {
        $privid = id -u                
        if ($privid -eq 0) {
            $isElevated = $true
        }
    }
    else {
        $isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    if (-not $isElevated) { Write-Error "This script must be run as an administrator."; return }

    $modulePath = Join-Path "$InstallPath" "atomic-red-team-master\execution-frameworks\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam.psm1"
    if ($Force -or -Not (Test-Path -Path $InstallPath )) {
        write-verbose "Directory Creation"
        if ($Force) {
            Try { 
                if (Test-Path $InstallPath){ Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction Stop | Out-Null }
            }
            Catch {
                Write-Host -ForegroundColor Red $_.Exception.Message
                return
            }
        }
        New-Item -ItemType directory -Path $InstallPath | Out-Null

        if ($IsWindows -or $null -eq $IsWindows) {
            write-verbose "Setting Execution Policy to Unrestricted"
            set-executionpolicy Unrestricted
        }

        write-verbose "Setting variables for remote URL and download Path"
        $url = "https://github.com/redcanaryco/atomic-red-team/archive/master.zip"
        $path = Join-Path $DownloadPath "master.zip"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $webClient = new-object System.Net.WebClient
        write-verbose "Beginning download from Github"
        $webClient.DownloadFile( $url, $path )

        write-verbose "Extracting ART to $InstallPath"
        $lp = Join-Path "$DownloadPath" "master.zip" 
        expand-archive -LiteralPath $lp -DestinationPath "$InstallPath" -Force:$Force

        if (-not $IsMacOS -and -not $IsLinux) {
            write-verbose "Installing NuGet PackageProvider"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        }
        else {
            chown -R $env:SUDO_USER`:$env:SUDO_USER $InstallPath
        }

        write-verbose "Installing powershell-yaml"
        Install-Module -Name powershell-yaml -Force

        write-verbose "Importing invoke-atomicRedTeam module"
        Import-Module $modulePath -Force

        Write-Host "Installation of Invoke-AtomicRedTeam is complete. You can now use the Invoke-AtomicTest function" -Fore Yellow
        Write-Host "See README at https://github.com/redcanaryco/atomic-red-team/tree/master/execution-frameworks/Invoke-AtomicRedTeam for complete details" -Fore Yellow

    }
    else {
        Write-Host -ForegroundColor Yellow "Atomic Redteam already exists at $InstallPath. No changes were made."
        Write-Host -ForegroundColor Cyan "Try the install again with the '-Force' parameter if you want to delete the existing installion and re-install."
        Write-Host -ForegroundColor Red "Warning: All files within the install directory ($InstallPath) will be deleted when using the '-Force' parameter."
    }
}
