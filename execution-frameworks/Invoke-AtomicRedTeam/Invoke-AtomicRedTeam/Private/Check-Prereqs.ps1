function Check-Prereqs ($test, $isElevated) {
    $FailureReasons = New-Object System.Collections.ArrayList
    if ($test.executor.elevation_required -and -not $isElevated) {
        $FailureReasons.add("Elevation required but not provided`n") | Out-Null
    }
    foreach ($dep in $test.dependencies) {
        $executor = Get-PrereqExecutor $test $dep
        $final_command = Replace-InputArgs $dep.prereq_command $test
        $success = Execute-Command $final_command $executor
        if (-not $success) {
            $FailureReasons.add($dep.description) | Out-Null
        }
    }
    $FailureReasons
}