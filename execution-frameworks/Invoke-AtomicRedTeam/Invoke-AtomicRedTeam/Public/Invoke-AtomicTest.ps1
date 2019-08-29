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
    PS/> Invoke-AtomicTest T1117 -GenerateOnly
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
        $GenerateOnly,

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
        $PathToAtomicsFolder = "..\..\atomics",

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $CheckPrereqs = $false,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $Cleanup = $false
    )
    BEGIN { } # Intentionally left blank and can be removed
    PROCESS {
        Write-Verbose -Message 'Attempting to run Atomic Techniques'

        $AtomicTechniqueHash = Get-AtomicTechnique -Path $PathToAtomicsFolder\$AtomicTechnique\$AtomicTechnique.yaml
        $techniqueCount = 0
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

                Write-Verbose -Message 'Determining tests for Windows'

                if (-Not $test.supported_platforms.Contains('windows')) {
                    Write-Verbose -Message 'Unable to run non-Windows tests'
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

                if ($test.input_arguments.Count -gt 0) {
                    Write-Verbose -Message 'Replacing inputArgs with default values'
                    $inputArgs = [Array]($test.input_arguments.Keys).Split(" ")
                    $inputDefaults = [Array]($test.input_arguments.Values | ForEach-Object { $_.default }).Split(" ")

                    for ($i = 0; $i -lt $inputArgs.Length; $i++) {
                        $findValue = '#{' + $inputArgs[$i] + '}'
                        if( $nul -ne $prereqCommand ) { $prereqCommand = $prereqCommand.Replace($findValue, $inputDefaults[$i]) } else { $prereqCommand = "" }
                        $Command = $command.Replace($findValue, $inputDefaults[$i])
                        if( $nul -ne $cleanupCommand ) { $cleanupCommand = $cleanupCommand.Replace($findValue, $inputDefaults[$i]) } else { $cleanupCommand = "" }
                    }
                }

                if ($CheckPrereqs) {
                    $finalCommand = $prereqCommand
                }
                elseif ($Cleanup) {
                    $finalCommand =  $cleanupCommand
                }
                else {
                    $finalCommand = $command
                }

                Write-Debug -Message 'Getting executor and build command script'

                if ($GenerateOnly) {
                    Write-Information -MessageData $finalCommand -Tags 'Command'
                }
                else {
                    Write-Verbose -Message 'Invoking Atomic Tests using defined executor'
                    $testName = $test.name.ToString()
                    if ($pscmdlet.ShouldProcess($testName, 'Execute Atomic Test')) {
                        switch ($test.executor.name) {
                            "command_prompt" {
                                Write-Information -MessageData "Command Prompt:`n $finalCommand" -Tags 'AtomicTest'
                                $finalCommandEscaped = $finalCommand -replace "`"", "```""
                                $execCommand = $finalCommandEscaped.Split("`n") | Where-Object { $_ -ne "" }
                                $exitCodes = New-Object System.Collections.ArrayList
                                $execCommand | ForEach-Object { 
                                    Invoke-Expression "cmd.exe /c `"$_`" " 
                                    $exitCodes.Add($LASTEXITCODE) | Out-Null
                                }
                                $nonZeroExitCodes = $exitCodes | Where-Object { $_ -ne 0 }
                                if ($CheckPrereqs ) {
                                    if ($nonZeroExitCodes.Count -ne 0) {
                                        Write-Host -ForegroundColor Red "Prerequisites not met: $testName"
                                    }
                                    else {
                                        Write-Host -ForegroundColor Green "Prerequisites met: $testName"
                                    }
                                }
                                continue
                            }
                            "powershell" {
                                Write-Information -MessageData "PowerShell`n $finalCommand" -Tags 'AtomicTest'
                                $execCommand = "Invoke-Command -ScriptBlock {$finalCommand}"
                                $res = Invoke-Expression $execCommand
                                if ($CheckPrereqs ) {
                                    if ([string]::IsNullOrEmpty($finalCommand) -or $res -ne 0) {
                                        Write-Host -ForegroundColor Red "Prerequisites not met: $testName"
                                    }
                                    else {
                                        Write-Host -ForegroundColor Green "Prerequisites met: $testName"
                                    }
                                }
                                continue
                            }
                            default {
                                Write-Warning -Message "Unable to generate or execute the command line properly."
                                continue
                            }
                        } # End of executor switch
                    } # End of if ShouldProcess block
                } # End of else statement
            } # End of foreach Test in single Atomic Technique

            Write-Information -MessageData "[!!!!!!!!END TEST!!!!!!!]`n`n" -Tags 'Details'

        } # End of foreach Technique in Atomic Tests
    } # End of PROCESS block
    END { } # Intentionally left blank and can be removed
}
Invoke-AtomicTest T1089 -TestNames "Uninstall Sysmon" -CheckPrereqs