function Get-PrereqExecutor ($test) {
    if ($nul -eq $test.dependencies.executor_name) { $executor = $dep.executor_name } 
    else { $executor = $test.executor.name }
    $executor
}