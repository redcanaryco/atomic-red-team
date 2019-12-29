function Write-PrereqResults ($FailureReasons, $testId) {
    if ($FailureReasons.Count -eq 0) {
        Write-KeyValue "Prerequisites met: " $testId
    }
    else {
        Write-Host -ForegroundColor Red "Prerequisites not met: $testId"
        foreach ($reason in $FailureReasons) {
            Write-Host -ForegroundColor Yellow -NoNewline "`t[*] $reason"
        }
    }
}