function Show-Details ($test, $testCount, $technique, $customInputArgs, $PathToAtomicsFolder) {
    # Header info
    $tName = $technique.display_name.ToString() + " " + $technique.attack_technique.ToString() 
    Write-KeyValue "[********BEGIN TEST*******]`nTechnique: "  $tName
    Write-KeyValue "Atomic Test Name: " $test.name.ToString()
    Write-KeyValue "Atomic Test Number: " $testCount
    Write-KeyValue "Description: " $test.description.ToString().trim()

    # Attack Commands
    Write-Host -ForegroundColor Yellow "Attack Commands:"
    $elevationRequired = $false
    if ($nul -ne $test.executor.elevation_required ) { $elevationRequired = $test.executor.elevation_required }
    $executor_name = $test.executor.name
    Write-KeyValue "Executor: " $executor_name
    Write-KeyValue "ElevationRequired: " $elevationRequired
    $final_command = Merge-InputArgs $test.executor.command $test $customInputArgs $PathToAtomicsFolder
    Write-KeyValue "Command:`n" $test.executor.command.trim()
    if ($test.executor.command -ne $final_command) { Write-KeyValue "Command (with inputs):`n" $final_command.trim() }

    # Cleanup Commands
    if ($nul -ne $test.executor.cleanup_command) {
        Write-Host -ForegroundColor Yellow "Cleanup Commands:"
        $final_command = Merge-InputArgs $test.executor.cleanup_command $test $customInputArgs $PathToAtomicsFolder
        Write-KeyValue "Command:`n" $test.executor.cleanup_command.trim()
        if ($test.executor.command -ne $final_command) { Write-KeyValue "Command (with inputs):`n" $final_command.trim() }
    }

    # Dependencies
    if ($nul -ne $test.dependencies) {
        Write-Host -ForegroundColor Yellow "Dependencies:"
        foreach ($dep in $test.dependencies) {
            $final_command_prereq = Merge-InputArgs $dep.prereq_command $test $customInputArgs $PathToAtomicsFolder
            $final_command_get_prereq = Merge-InputArgs $dep.get_prereq_command $test $customInputArgs $PathToAtomicsFolder
            $description = Merge-InputArgs $dep.description $test $customInputArgs $PathToAtomicsFolder
            Write-KeyValue "Description: " $description.trim()
            Write-KeyValue "Check Prereq Command:`n" $dep.prereq_command.trim()
            if ( $dep.prereq_command -ne $final_command_prereq ) { Write-KeyValue "Check Prereq Command (with inputs):`n" $final_command_prereq.trim() }
            Write-KeyValue "Get Prereq Command:`n" $dep.get_prereq_command.trim()
            if ( $dep.get_prereq_command -ne $final_command_get_prereq ) { Write-KeyValue "Get Prereq Command (with inputs):`n" $final_command_get_prereq.trim() }
        }
    }
    # Footer
    Write-Host -Fore Cyan "[!!!!!!!!END TEST!!!!!!!]`n`n"

}