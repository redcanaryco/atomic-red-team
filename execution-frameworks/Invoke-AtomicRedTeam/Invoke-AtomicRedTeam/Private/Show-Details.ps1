function Show-Details ($test, $testCount, $technique, $PathToAtomicsFolder) {
    # Header info
    $tName = $technique.display_name.ToString() + " " + $technique.attack_technique.ToString() 
    Write-KeyValue "[********BEGIN TEST*******]`nTechnique: "  $tName
    Write-KeyValue "Atomic Test Name: " $test.name.ToString()
    Write-KeyValue "Atomic Test Number: " $testCount
    Write-KeyValue "Description: " $test.description.ToString().trim()

    # Dependencies
    if ($nul -ne $test.dependencies) {
        Write-Host -ForegroundColor Yellow "Dependencies:"
        foreach ($dep in $test.dependencies) {
            $final_command_prereq = Replace-InputArgs $dep.prereq_command $test $PathToAtomicsFolder
            $final_command_get_prereq = Replace-InputArgs $dep.get_prereq_command $test $PathToAtomicsFolder
            Write-KeyValue "Description: " $dep.description.trim()
            Write-KeyValue "Check Prereq Command: " $dep.prereq_command.trim()
            if ( $dep.prereq_command -ne $final_command_prereq ) { Write-KeyValue "Check Prereq Command (with inputs): " $final_command_prereq.trim() }
            Write-KeyValue "Get Prereq Command: " $dep.get_prereq_command.trim()
            if ( $dep.get_prereq_command -ne $final_command_get_prereq ) { Write-KeyValue "Get Prereq Command (with inputs): " $final_command_get_prereq.trim() }
        }
    }

    # Attack Commands
    Write-Host -ForegroundColor Yellow "Attack Commands:"
    $executor_name = $test.executor.name
    Write-KeyValue "Executor: " $executor_name
    Write-KeyValue "ElevationRequired: " $test.executor.elevation_required
    $final_command = Replace-InputArgs $test.executor.command $test $PathToAtomicsFolder
    Write-KeyValue "Command: " $test.executor.command.trim()
    if ($test.executor.command -ne $final_command) { Write-KeyValue "Command (with inputs): " $final_command.trim() }

    # Cleanup Commands
    if ($nul -ne $test.executor.cleanup_command) {
        Write-Host -ForegroundColor Yellow "Cleanup Commands:"
        $final_command = Replace-InputArgs $test.executor.cleanup_command $test $PathToAtomicsFolder
        Write-KeyValue "Command: " $test.executor.cleanup_command.trim()
        if ($test.executor.command -ne $final_command) { Write-KeyValue "Command (with inputs): " $final_command.trim() }
    }

    # Footer
    Write-Host -Fore Blue "[!!!!!!!!END TEST!!!!!!!]`n`n"

}