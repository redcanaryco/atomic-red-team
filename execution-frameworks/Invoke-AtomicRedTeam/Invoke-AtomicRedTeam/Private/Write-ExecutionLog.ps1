function Write-ExecutionLog($startTime, $technique, $testNum, $testName, $logPath) {
    if (!(Test-Path $logPath)) { 
        New-Item $logPath -Force -ItemType File 
    } 

    $timeUTC = (Get-Date($startTime).toUniversalTime() -uformat "%Y-%m-%dT%H:%m:%SZ").ToString()
    $timeLocal = (Get-Date($startTime) -uformat "%Y-%m-%dT%H:%m:%SZ").ToString()
    [PSCustomObject][ordered]@{ "Execution Time (UTC)" = $timeUTC; "Execution Time (Local)" = $timeLocal; "Technique" = $technique; "Test Number" = $testNum; "Test Name" = $testName } | Export-Csv -Path $LogPath -NoTypeInformation -Append
}