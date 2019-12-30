function Get-InputArgs([hashtable]$ip, $customInputArgs, $PathToAtomicsFolder) {
    $defaultArgs = @{ }
    foreach ($key in $ip.Keys) {
        $defaultArgs[$key] = $ip[$key].default
    }
    # overwrite defaults with any user supplied values
    foreach ($key in $customInputArgs.Keys) {
        if ($defaultArgs.Keys -contains $key) {
            # replace default with user supplied
            $defaultArgs.set_Item($key, $customInputArgs[$key])
        }
    }
    # Replace $PathToAtomicsFolder or PathToAtomicsFolder with the actual -PathToAtomicsFolder value
    foreach ($key in $defaultArgs.Clone().Keys) {
        $defaultArgs.set_Item($key, ($defaultArgs[$key] -replace "\`$PathToAtomicsFolder", $PathToAtomicsFolder -replace "PathToAtomicsFolder", $PathToAtomicsFolder))
    }
    $defaultArgs
}

function Replace-InputArgs($finalCommand, $test, $customInputArgs, $PathToAtomicsFolder) {
    if (($null -ne $finalCommand) -and ($test.input_arguments.Count -gt 0)) {
        Write-Verbose -Message 'Replacing inputArgs with user specified values, or default values if none provided'
        $inputArgs = Get-InputArgs $test.input_arguments $customInputArgs $PathToAtomicsFolder

        foreach ($key in $inputArgs.Keys) {
            $findValue = '#{' + $key + '}'
            $finalCommand = $finalCommand.Replace($findValue, $inputArgs[$key])
        }
    }
    $finalCommand
}