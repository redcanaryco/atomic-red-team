function Get-PrereqExecutor ($test, $dep) {
    if ($nul -eq $dep.executor_name) { $executor = $test.executor.name } 
    else { $executor = $dep.executor_name }
    $executor
}