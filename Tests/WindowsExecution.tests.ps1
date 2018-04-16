Import-Module ..\Automation\AtomicRedTeam.psd1 -Force

$sysmonAvailable = Get-WinEvent -ListLog Microsoft-Windows-Sysmon/Operational -ErrorAction Ignore
if(-not $sysmonAvailable)
{
    Write-Warning "Warning: SYSMON is not installed. Many test validations will be unavailable. Please install SYSMON."
}
else {
    wevtutil cl Microsoft-Windows-Sysmon/Operational
}

Describe "Tests for Windows/Execution" {

    It "Validates BitsAdmin" {

        $null = Invoke-ArtAction -Action Windows/Execution/BitsAdmin
        Test-Path $env:TEMP\AtomicRedTeam\bitsadmin_flag.ps1 | Should be $true
    }

    It "Validates MSBuild Trusted Developer Utilities" {

        $result = Invoke-ArtAction -Action Windows/Execution/Trusted_Developer_Utilities/MSBuild
        $result -match "Hello From" | Measure-Object | Foreach-Object Count | Should be 2
    }
}