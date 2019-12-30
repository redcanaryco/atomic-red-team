function Get-PrereqExecutor ($test) {
    if ($nul -eq $test.dependency_executor_name) { $executor = $test.executor.name } 
    else { $executor = $test.dependency_executor_name }
    $executor
}