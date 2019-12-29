
        function Execute-Command ($finalCommand, $executor) {
            $success = $true
            Write-Verbose -Message 'Invoking Atomic Tests using defined executor'
            # $testName = $test.name.ToString()
            # if ($pscmdlet.ShouldProcess($testName, 'Execute Atomic Test')) {
                # $executor = $test.executor.name
                $finalCommandEscaped = $finalCommand -replace "`"", "```""
                if ($executor -eq "command_prompt" -or $executor -eq "sh" -or $executor -eq "bash") {
                    $execCommand = $finalCommandEscaped.Split("`n") | Where-Object { $_ -ne "" }
                    $exitCodes = New-Object System.Collections.ArrayList
                    $execPrefix = "cmd.exe /c"
                    if ($executor -eq "sh") { $execPrefix = "sh -c" }
                    if ($executor -eq "bash") { $execPrefix = "bash -c" }
                    $execCommand | ForEach-Object {
                        Invoke-Expression "$execPrefix `"$_`" "
                        $exitCodes.Add($LASTEXITCODE) | Out-Null
                    }
                    $nonZeroExitCodes = $exitCodes | Where-Object { $_ -ne 0 }
                    $success = $nonZeroExitCodes.Count -eq 0                             
                }
                elseif ($executor -eq "powershell") {
                    $execCommand = "Invoke-Command -ScriptBlock {$finalCommand}"
                    $res = Invoke-Expression $execCommand
                    $success = [string]::IsNullOrEmpty($finalCommand) -or $res -eq 0
                }
                else { 
                    Write-Warning -Message "Unable to generate or execute the command line properly. Unknown executor"
                    $success = $false
                }
            # } # End of if ShouldProcess block
            $success
        }