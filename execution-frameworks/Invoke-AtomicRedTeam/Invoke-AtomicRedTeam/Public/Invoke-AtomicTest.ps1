<#
.SYNOPSIS
    Invokes specified Atomic test(s)
.DESCRIPTION
    Invokes specified Atomic tests(s).  Optionally, you can specify if you want to generate Atomic test(s) only.
.EXAMPLE Check if Prerequisites for Atomic Test are met
    PS/> Invoke-AtomicTest T1117 -CheckPrereqs
.EXAMPLE Invokes Atomic Test
    PS/> Invoke-AtomicTest T1117
.EXAMPLE Run the Cleanup Commmand for the given Atomic Test
    PS/> Invoke-AtomicTest T1117 -Cleanup
.EXAMPLE Generate Atomic Test (Output Test Definition Details)
    PS/> Invoke-AtomicTest T1117 -ShowDetails
.NOTES
    Create Atomic Tests from yaml files described in Atomic Red Team. https://github.com/redcanaryco/atomic-red-team
.LINK
    Blog: http://subt0x11.blogspot.com/2018/08/invoke-atomictest-automating-mitre-att.html
    Github repo: https://github.com/redcanaryco/atomic-red-team
#>
function Invoke-AtomicTest {
    [CmdletBinding(DefaultParameterSetName = 'technique',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    Param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [ValidateNotNullOrEmpty()]
        [String]
        $AtomicTechnique,

        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $ShowDetails,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [String[]]
        $TestNumbers,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [String[]]
        $TestNames,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [String]
        $PathToAtomicsFolder = $( if($IsLinux -or $IsMacOS) {$Env:HOME + "/AtomicRedTeam/atomic-red-team-master/atomics"} else{$env:HOMEDRIVE + "\AtomicRedTeam\atomic-red-team-master\atomics"}),

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $CheckPrereqs = $false,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $Cleanup = $false,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [switch]
        $NoExecutionLog = $false,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [String]
        $ExecutionLogPath = "Invoke-AtomicTest-ExecutionLog.csv",

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [switch]
        $Force,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [HashTable]
        $InputArgs
    )
    BEGIN { } # Intentionally left blank and can be removed
    PROCESS {
        # $InformationPrefrence = 'Continue'
        Write-Verbose -Message 'Attempting to run Atomic Techniques'
        $isElevated = $false
        $targetPlatform = "linux"
        if ($IsLinux -or $IsMacOS){
            if ($IsMacOS){ $targetPlatform = "macos"}
            $privid = id -u                
            if ($privid -eq 0){ $isElevated = $true }
        }
        else {
            $targetPlatform = "windows"
            $isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }

        Write-Host -ForegroundColor Cyan "PathToAtomicsFolder = $PathToAtomicsFolder`n"

        function Get-InputArgs([hashtable]$ip) {
            $defaultArgs = @{ }
            foreach ($key in $ip.Keys) {
                $defaultArgs[$key] = $ip[$key].default
            }
            # overwrite defaults with any user supplied values
            foreach ($key in $InputArgs.Keys) {
                if ($defaultArgs.Keys -contains $key) {
                    # replace default with user supplied
                    $defaultArgs.set_Item($key, $InputArgs[$key])
                }
            }
            # Replace $PathToAtomicsFolder or PathToAtomicsFolder with the actual -PathToAtomicsFolder value
            foreach ($key in $defaultArgs.Clone().Keys) {
                $defaultArgs.set_Item($key, ($defaultArgs[$key] -replace "\`$PathToAtomicsFolder",$PathToAtomicsFolder -replace "PathToAtomicsFolder",$PathToAtomicsFolder))
            }
            $defaultArgs
        }

        function Write-PrereqResults ($success) {
            if ($CheckPrereqs ) {
                if ($test.executor.elevation_required -and -not $isElevated) {
                    Write-Host -ForegroundColor Red "Prerequisites not met: $testId (elevation required but not provided)"
                }
                elseif ($success) {
                    Write-Host -ForegroundColor Green "Prerequisites met: $testId"
                }
                else {
                    Write-Host -ForegroundColor Red "Prerequisites not met: $testId"
                }
            }
            elseif ($test.executor.elevation_required -and -not $isElevated) {
                Write-Host -ForegroundColor yellow "Warning: Test '$testId' should be run from an elevated context but wasn't. Try running this test with administrative privileges. "
            }
        }

        function Invoke-AtomicTestSingle ($AT) {

            $AT=$AT.ToUpper()
            $pathToYaml = Join-Path $PathToAtomicsFolder "\$AT\$AT.yaml"
            if (Test-Path -Path $pathToYaml){$AtomicTechniqueHash = Get-AtomicTechnique -Path $pathToYaml}
            else{
                Write-Information -MessageData "ERROR: $PathToYaml does not exist`nCheck your Atomic Number and Path to Atomics"
                continue
            }
            $techniqueCount = 0
            if ($technique -eq $null){ Write-Information -MessageData "There are no $targetPlatform tests in $AT "}
            foreach ($technique in $AtomicTechniqueHash) {

                $techniqueCount++

                $props = @{
                    Activity        = "Running $($technique.display_name.ToString()) Technique"
                    Status          = 'Progress:'
                    PercentComplete = ($techniqueCount / ($AtomicTechniqueHash).Count * 100)
                }
                Write-Progress @props

                Write-Debug -Message "Gathering tests for Technique $technique"

                $testCount = 0
                foreach ($test in $technique.atomic_tests) {
                    $testCount++

                    if ($null -ne $TestNumbers) {
                        if (-Not ($TestNumbers -contains $testCount) ) { continue }
                    }

                    if ($null -ne $TestNames) {
                        if (-Not ($TestNames -contains $test.name) ) { continue }
                    }

                    $props = @{
                        Activity        = 'Running Atomic Tests'
                        Status          = 'Progress:'
                        PercentComplete = ($testCount / ($technique.atomic_tests).Count * 100)
                    }
                    Write-Progress @props

                    Write-Verbose -Message 'Determining tests for target operating system'

                    if (-Not $test.supported_platforms.Contains($targetPlatform)) {
                        Write-Verbose -Message "Unable to run non-$targetPlatform tests"
                        continue
                    }

                    Write-Verbose -Message 'Determining manual tests'

                    if ($test.executor.name.Contains('manual')) {
                        Write-Verbose -Message 'Unable to run manual tests'
                        continue
                    }

                    Write-Information -MessageData ("[********BEGIN TEST*******]`n" +
                        $technique.display_name.ToString(), $technique.attack_technique.ToString()) -Tags 'Details'
                
                    Write-Information -MessageData $test.name.ToString() -Tags 'Details'
                    Write-Information -MessageData $test.description.ToString() -Tags 'Details'

                    Write-Debug -Message 'Gathering final Atomic test command'

                    $prereqCommand = $test.executor.prereq_command
                    $command = $test.executor.command
                    $cleanupCommand = $test.executor.cleanup_command

                    if ($CheckPrereqs) {
                        $finalCommand = $prereqCommand
                    }
                    elseif ($Cleanup) {
                        $finalCommand = $cleanupCommand
                    }
                    else {
                        $finalCommand = $command
                    }

                    if (($null -ne $finalCommand) -and ($test.input_arguments.Count -gt 0)) {
                        Write-Verbose -Message 'Replacing inputArgs with user specified values, or default values if none provided'
                        $inputArgs = Get-InputArgs $test.input_arguments

                        foreach ($key in $inputArgs.Keys) {
                            $findValue = '#{' + $key + '}'
                            $finalCommand = $finalCommand.Replace($findValue, $inputArgs[$key])
                        }
                    }

                    Write-Debug -Message 'Getting executor and build command script'

                    if ($ShowDetails -and ($null -ne $finalCommand)) {
                        Write-Information -MessageData $finalCommand -Tags 'Command'
                    }
                    else {
                        $startTime = get-date
                        Write-Verbose -Message 'Invoking Atomic Tests using defined executor'
                        $testName = $test.name.ToString()
                        if ($pscmdlet.ShouldProcess($testName, 'Execute Atomic Test')) {
                            $testId = "$AT-$testCount $testName"
                            $attackExecuted = $false
                            $executor = $test.executor.name
                            $finalCommandEscaped = $finalCommand -replace "`"", "```""
                            Write-Information -MessageData $finalCommandEscaped
                            if ($executor -eq "command_prompt" -or $executor -eq "sh" -or $executor -eq "bash"){
                                $execCommand = $finalCommandEscaped.Split("`n") | Where-Object { $_ -ne "" }
                                $exitCodes = New-Object System.Collections.ArrayList
                                $execPrefix = "cmd.exe /c"
                                if ($executor -eq "sh"){$execPrefix = "sh -c"}
                                if ($executor -eq "bash"){$execPrefix = "bash -c"}
                                $execCommand | ForEach-Object {
                                    Invoke-Expression "$execPrefix `"$_`" "
                                    $exitCodes.Add($LASTEXITCODE) | Out-Null
                                }
                                $nonZeroExitCodes = $exitCodes | Where-Object { $_ -ne 0 }
                                $success = $nonZeroExitCodes.Count -eq 0                             
                            }
                            elseif ($executor -eq "powershell"){
                                $execCommand = "Invoke-Command -ScriptBlock {$finalCommand}"
                                $res = Invoke-Expression $execCommand
                                $success = [string]::IsNullOrEmpty($finalCommand) -or $res -eq 0
                            }
                            else { 
                                Write-Warning -Message "Unable to generate or execute the command line properly."
                                continue
                            }
                            if (!$CheckPrereqs -and !$Cleanup) { $attackExecuted = $true }
                            Write-PrereqResults ($success) $testId
                            if (-not $NoExecutionLog -and $attackExecuted) { Write-ExecutionLog $startTime $AT $testCount $testName $ExecutionLogPath}
                        } # End of if ShouldProcess block
                    } # End of else statement
                    Write-Information -MessageData "[!!!!!!!!END TEST!!!!!!!]`n`n" -Tags 'Details'
                } # End of foreach Test in single Atomic Technique
            } # End of foreach Technique in Atomic Tests
        } # End of Invoke-AtomicTestSingle function

        if ($AtomicTechnique -eq "All") {
            function Invoke-AllTests() {
                $AllAtomicTests = New-Object System.Collections.ArrayList
                Get-ChildItem $PathToAtomicsFolder -Recurse -Filter *.yaml -File | ForEach-Object {
                    $currentTechnique = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
                    if ( $currentTechnique -ne "index" ) { $AllAtomicTests.Add($currentTechnique) | Out-Null }
                }
                $AllAtomicTests.GetEnumerator() | Foreach-Object { Invoke-AtomicTestSingle $_ }
            }
        
            if ( ($Force -or $CheckPrereqs) -or $psCmdlet.ShouldContinue( 'Do you wish to execute all tests?',
                    "Highway to the danger zone, Executing All Atomic Tests!" ) ) {
                Invoke-AllTests
            }
        }
        else {
            Invoke-AtomicTestSingle $AtomicTechnique
        }

    } # End of PROCESS block
    END { } # Intentionally left blank and can be removed
}
