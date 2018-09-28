Import-Module ..\Automation\AtomicRedTeam.psd1 -Force

$sysmonAvailable = Get-WinEvent -ListLog Microsoft-Windows-Sysmon/Operational -ErrorAction Ignore
if(-not $sysmonAvailable)
{
    Write-Warning "Warning: SYSMON is not installed. Many test validations will be unavailable. Please install SYSMON."
}
else {
    wevtutil cl Microsoft-Windows-Sysmon/Operational
}

Describe "Tests for Windows/LateralMovement" {

    It "Validates RDP Session Hijacking lateral movement" {

        $startTime = Get-Date

        $null = Invoke-ArtAction -Action Windows/Lateral_Movement/Remote_Desktop_Protocol_Hijack
        Start-Sleep -Seconds 1
        
        if($sysmonAvailable)
        {
            $records = Get-WinEvent -LogName Microsoft-Windows-Sysmon/Operational |
                Where-Object { ($_.Id -eq 1) -and ($_.Message -match 'tscon') -and ($_.TimeCreated -ge $startTime) }
            ($records.Count -gt 0) | Should be $true
        }
        else
        {
            Write-Warning "Warning: Validation skipped for RDP Session Hijacking. Please install SYSMON"
        }
    }

}