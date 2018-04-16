Import-Module ..\Automation\AtomicRedTeam.psd1 -Force

$sysmonAvailable = Get-WinEvent -ListLog Microsoft-Windows-Sysmon/Operational -ErrorAction Ignore
if(-not $sysmonAvailable)
{
    Write-Warning "Warning: SYSMON is not installed. Many test validations will be unavailable. Please install SYSMON."
}
else {
    wevtutil cl Microsoft-Windows-Sysmon/Operational
}

Describe "Tests for Windows/DefenseEvasion" {

    It "Validates clearing the System event log" {

        $startTime = Get-Date

        $null = Invoke-ArtAction -Action Windows/Defense_Evasion/Indicator_Removal_on_Host/System -Force
        Start-Sleep -Seconds 1
        
        if($sysmonAvailable)
        {
            $records = Get-WinEvent -LogName System |
                Where-Object { ($_.Id -eq 104) -and ($_.Message -match 'cleared') -and ($_.TimeCreated -ge $startTime) }
            ($records.Count -gt 0) | Should be $true
        }
        else
        {
            Write-Warning "Warning: Validation skipped for RDP Session Hijacking. Please install SYSMON"
        }
    }

}