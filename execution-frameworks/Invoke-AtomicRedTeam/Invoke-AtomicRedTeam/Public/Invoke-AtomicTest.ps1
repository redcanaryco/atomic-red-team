<#
.SYNOPSIS
    Invokes provided Atomic test(s)
.DESCRIPTION
    Invokes provided Atomic tests(s).  Optionally, you can specify if you want to generate Atomic test(s) only.
.EXAMPLE Invokes Atomic Test
    PS/> $T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
    PS/> Invoke-AtomicTest $T1117
.EXAMPLE Generate Atomic Test
    PS/> $T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
    PS/> Invoke-AtomicTest $T1117 -GenerateOnly
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
        [System.Collections.Hashtable]
        $AtomicTechnique,

        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $GenerateOnly
    )
    BEGIN { } # Intentionally left blank and can be removed
    PROCESS {
        Write-Verbose -Message 'Attempting to run Atomic Techniques'

        $techniqueCount = 0
        foreach ($technique in $AtomicTechnique) {

            $techniqueCount++

            $props = @{
                Activity        = "Running $($technique.display_name.ToString()) Technique"
                Status          = 'Progress:'
                PercentComplete = ($techniqueCount / ($AtomicTechnique).Count * 100)
            }
            Write-Progress @props

            Write-Debug -Message "Gathering tests for Technique $technique"

            $testCount = 0
            foreach ($test in $technique.atomic_tests) {
                $testCount++

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

                $finalCommand = $test.executor.command

                if ($test.input_arguments.Count -gt 0) {
                    Write-Verbose -Message 'Replacing inputArgs with default values'
                    $inputArgs = [Array]($test.input_arguments.Keys).Split(" ")
                    $inputDefaults = [Array]($test.input_arguments.Values | ForEach-Object {$_.default }).Split(" ")

                    for ($i = 0; $i -lt $inputArgs.Length; $i++) {
                        $findValue = '#{' + $inputArgs[$i] + '}'
                        $finalCommand = $finalCommand.Replace($findValue, $inputDefaults[$i])
                    }
                }

                Write-Debug -Message 'Getting executor and build command script'

                if ($GenerateOnly) {
                    Write-Information -MessageData $finalCommand -Tags 'Command'
                }
                else {
                    Write-Verbose -Message 'Invoking Atomic Tests using defined executor'
                    if ($pscmdlet.ShouldProcess(($test.name.ToString()), 'Execute Atomic Test')) {
                        switch ($test.executor.name) {
                            "command_prompt" {
                                Write-Information -MessageData "Command Prompt:`n $finalCommand" -Tags 'AtomicTest'
                                $finalCommandEscaped = $finalCommand -replace "`"","```""
                                $execCommand = $finalCommandEscaped.Split("`n")
                                $execCommand | ForEach-Object { Invoke-Expression "cmd.exe /c `"$_`" " }
                                continue
                            }
                            "powershell" {
                                Write-Information -MessageData "PowerShell`n $finalCommand" -Tags 'AtomicTest'
                                $execCommand = "Invoke-Command -ScriptBlock {$finalCommand}"
                                Invoke-Expression $execCommand
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