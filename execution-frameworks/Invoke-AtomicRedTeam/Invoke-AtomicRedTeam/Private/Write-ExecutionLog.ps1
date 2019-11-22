function Write-ExecutionLog($startTime, $technique, $testNum, $testName, $logPath) {
    if (!(Test-Path $logPath)) { 
        New-Item $logPath -Force -ItemType File | Out-Null
    } 

    $timeUTC = (Get-Date($startTime).toUniversalTime() -uformat "%Y-%m-%dT%H:%M:%SZ").ToString()
    $timeLocal = (Get-Date($startTime) -uformat "%Y-%m-%dT%H:%M:%S").ToString()
    $ArtHostname = hostname
    $ArtUser = whoami
    [PSCustomObject][ordered]@{ "Execution Time (UTC)" = $timeUTC; "Execution Time (Local)" = $timeLocal; "Technique" = $technique; "Test Number" = $testNum; "Test Name" = $testName; "Hostname" = $ArtHostname; "Username" = $ArtUser } | Export-Csv -Path $LogPath -NoTypeInformation -Append
}