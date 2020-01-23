function Invoke-CheckPrereqs ($test, $isElevated, $customInputArgs, $PathToAtomicsFolder) {
    $FailureReasons = New-Object System.Collections.ArrayList
    if ($test.executor.elevation_required -and -not $isElevated) {
        $FailureReasons.add("Elevation required but not provided`n") | Out-Null
    }
    foreach ($dep in $test.dependencies) {
        $executor = Get-PrereqExecutor $test
        $final_command = Merge-InputArgs $dep.prereq_command $test $customInputArgs $PathToAtomicsFolder
        $success = Invoke-ExecuteCommand $final_command $executor
        $description = Merge-InputArgs $dep.description $test $customInputArgs $PathToAtomicsFolder
        if (-not $success) {
            $FailureReasons.add($description) | Out-Null
        }
    }
    $FailureReasons
}