<#
.SYNOPSIS
This script will iterate over the Atomic Red Team yaml files, create objects for each test.
The aim is to allow defenders to excercise MITRE ATT&CK Techniques to test defenses.

Function: Invoke-AtomicRedTeam
Author: Casey Smith @subTee
License:  http://opensource.org/licenses/MIT
Required Dependencies: powershell-yaml , Install-Module powershell-yaml #https://github.com/cloudbase/powershell-yaml
Optional Dependencies: None
Version: 1.0

.DESCRIPTION
Create Atomic Tests from yaml files described in Atomic Red Team. https://github.com/redcanaryco/atomic-red-team

.EXAMPLE Convert Single Yaml File to Technique Object
$T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
.EXAMPLE Generate the Atomic Tests For A Given Technique, don't execute.
Invoke-AtomicTest $T1117 -GenerateOnly
.EXAMPLE Execute the Atomic Tests For A Given Technique
$T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
Invoke-AtomicTest $T1117
.NOTES
This script converts Atomic Tests Expressed in YAML into PowerShell Objects.

.LINK
Blog: http://subt0x11.blogspot.com/2018/08/invoke-atomictest-automating-mitre-att.html
Github repo: https://github.com/redcanaryco/atomic-red-team

#>

function Confirm-Dependencies {
    [CmdletBinding(DefaultParameterSetName = 'dependencies',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    Param ( )
    
    Write-Verbose -Message 'Checking whether powershell-yaml is installed'

    try {
        if (-not(Get-Module -Name 'powershell-yaml' -ListAvailable)) {
            if ($pscmdlet.ShouldProcess("PowerShell-Yaml Module", "Install required module")) {
                Install-Module -Name powershell-yaml -Force
                Write-Verbose -Message 'Successfully installed powershell-yaml module'
            }
        }
    }
    catch {
        Write-Error -ErrorRecord $Error[0] -RecommendedAction 'Please install powershell-yaml before continuing'
        throw 'Unable to install powershell-yaml'
    }

    try {
        Write-Verbose -Message 'Importing powershell-yaml module'
        Import-Module -Name powershell-yaml -Force
    }
    catch {
        Write-Error -ErrorRecord $Error[0] -RecommendedAction 'Please import the powershell-yaml module before continuing'
        throw 'Unable to import the powershell-yaml module'
    }
}

function Get-AtomicTechnique {
    [CmdletBinding(DefaultParameterSetName = 'technique',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        ConfirmImpact = 'Medium')]
    Param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )
    
    Write-Debug -Message "Getting atomic technique from $Path"

    Process 
    {
        Write-Verbose -Message 'Attempting to convert files from yaml'
        foreach ($File in $Path) {
            if ($pscmdlet.ShouldProcess($File, 'Converting yaml file')) {
                Write-Verbose -Message "Converting $File from Yaml"]
                $parsedYaml = (ConvertFrom-Yaml (Get-Content $File -Raw))
                Write-Output $parsedYaml
            }
        }
    }
}

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
        [ValidateNotNull()]
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
        foreach ($Technique in $AtomicTechnique) {
            $techniqueCount++
            Write-Progress -Activity "Running $($Technique.display_name.ToString()) Technique" -Status 'Progress:' -PercentComplete ($techniqueCount / ($AtomicTechnique).Count * 100)
            Write-Debug -Message "Gathering tests for Technique $Technique"

            $testCount = 0
            foreach ($Test in $Technique.atomic_tests) {
                $testCount++
                Write-Progress -Activity 'Running Atomic Tests' -Status 'Progress:' -PercentComplete ($testCount / ($Technique.atomic_tests).Count * 100)

                Write-Verbose -Message 'Determining tests for Windows'
                if (-Not $Test.supported_platforms.Contains('windows')) {
                    Write-Verbose -Message 'Unable to run non-Windows tests'
                    continue
                }

                Write-Verbose -Message 'Determining manual tests'
                if ($Test.executor.name.Contains('manual')) {
                    Write-Verbose -Message 'Unable to run manual tests'
                    continue
                }

                Write-Information -MessageData ("[********BEGIN TEST*******]`n" +
                    $Technique.display_name.ToString(), $Technique.attack_technique.ToString()) -Tags 'Details'
                
                Write-Information -MessageData $Test.name.ToString() -Tags 'Details'
                Write-Information -MessageData $Test.description.ToString() -Tags 'Details'

                Write-Debug -Message 'Gathering final executation command'
                $finalCommand = $Test.executor.command

                if ($Test.input_arguments.Count -gt 0) {
                    Write-Verbose -Message 'Replacing InputArgs with default values'
                    $InputArgs = [Array]($Test.input_arguments.Keys).Split(" ")
                    $InputDefaults = [Array]($Test.input_arguments.Values | ForEach-Object {$_.default }).Split(" ")

                    for ($i = 0; $i -lt $InputArgs.Length; $i++) {
                        $findValue = '#{' + $InputArgs[$i] + '}'
                        $finalCommand = $finalCommand.Replace($findValue, $InputDefaults[$i])
                    }
                }

                Write-Debug -Message 'Getting executor and build command script'
                if ($GenerateOnly) {
                    Write-Information -MessageData $finalCommand -Tags 'Command'
                }
                else {
                    Write-Verbose -Message 'Invoking Atomic Tests using defined executor'
                    if ($pscmdlet.ShouldProcess(($Test.name.ToString()), 'Execute Atomic Test')) {
                        switch ($Test.executor.name) {

                            "command_prompt" {
                                Write-Information -MessageData "Command Prompt:`n $finalCommand" -Tags 'AtomicTest'
                                $execCommand = $finalCommand.Split("`n")
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

Confirm-Dependencies