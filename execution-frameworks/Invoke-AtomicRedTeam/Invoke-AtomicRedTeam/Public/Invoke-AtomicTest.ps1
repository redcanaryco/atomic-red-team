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
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $ShowDetailsBrief,

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
        $PathToAtomicsFolder = $( if ($IsLinux -or $IsMacOS) { $Env:HOME + "/AtomicRedTeam/atomics" } else { $env:HOMEDRIVE + "\AtomicRedTeam\atomics" }),

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $CheckPrereqs = $false,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $GetPrereqs = $false,

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
        $InputArgs,
    
        [Parameter(Mandatory = $false,
            ParameterSetName = 'technique')]
        [Int]
        $TimeoutSeconds = 120
    )
    BEGIN { } # Intentionally left blank and can be removed
    PROCESS {
        Write-Verbose -Message 'Attempting to run Atomic Techniques'
        Write-Host -ForegroundColor Cyan "PathToAtomicsFolder = $PathToAtomicsFolder`n"
        
        $isElevated = $false
        $targetPlatform = "linux"
        if ($IsLinux -or $IsMacOS) {
            if ($IsMacOS) { $targetPlatform = "macos" }
            $privid = id -u                
            if ($privid -eq 0) { $isElevated = $true }
        }
        else {
            $targetPlatform = "windows"
            $isElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        
        function Invoke-AtomicTestSingle ($AT) {

            $AT = $AT.ToUpper()
            $pathToYaml = Join-Path $PathToAtomicsFolder "\$AT\$AT.yaml"
            if (Test-Path -Path $pathToYaml) { $AtomicTechniqueHash = Get-AtomicTechnique -Path $pathToYaml }
            else {
                Write-Host -Fore Red "ERROR: $PathToYaml does not exist`nCheck your Atomic Number and your PathToAtomicsFolder parameter"
                continue
            }
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

                    Write-Verbose -Message 'Determining tests for target operating system'

                    $testCount++

                    if (-Not $test.supported_platforms.Contains($targetPlatform)) {
                        Write-Verbose -Message "Unable to run non-$targetPlatform tests"
                        continue
                    }

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

                    Write-Verbose -Message 'Determining manual tests'

                    if ($test.executor.name.Contains('manual')) {
                        Write-Verbose -Message 'Unable to run manual tests'
                        continue
                    }

                    $testId = "$AT-$testCount $($test.name)"
                    if ($ShowDetails) {
                        Show-Details $test $testCount $technique $InputArgs $PathToAtomicsFolder
                        continue
                    }
                    if($ShowDetailsBrief){
                        Write-KeyValue $testId
                        continue
                    }

                    Write-Debug -Message 'Gathering final Atomic test command'


                    if ($CheckPrereqs) {
                        Write-KeyValue "CheckPrereq's for: " $testId
                        $failureReasons = Invoke-CheckPrereqs $test $isElevated $InputArgs $PathToAtomicsFolder $TimeoutSeconds
                        Write-PrereqResults $FailureReasons $testId
                    }
                    elseif ($GetPrereqs) {
                        Write-KeyValue "GetPrereq's for: " $testId
                        if ($nul -eq $test.dependencies) { Write-KeyValue "No Preqs Defined"; continue }
                        foreach ($dep in $test.dependencies) {
                            $executor = Get-PrereqExecutor $test
                            $description = (Merge-InputArgs $dep.description $test $InputArgs $PathToAtomicsFolder).trim()
                            Write-KeyValue  "Attempting to satisfy prereq: " $description
                            $final_command_prereq = Merge-InputArgs $dep.prereq_command $test $InputArgs $PathToAtomicsFolder
                            $final_command_prereq = ($final_command_prereq.trim()).Replace("`n", " && ")
                            $final_command_get_prereq = Merge-InputArgs $dep.get_prereq_command $test $InputArgs $PathToAtomicsFolder
                            $res = Invoke-ExecuteCommand $final_command_prereq $executor $TimeoutSeconds

                            if ($res -eq 0) {
                                Write-KeyValue "Prereq already met: " $description
                            }
                            else {
                                $res = Invoke-ExecuteCommand $final_command_get_prereq $executor $TimeoutSeconds 
                                $res = Invoke-ExecuteCommand $final_command_prereq $executor $TimeoutSeconds
                                if ($res -eq 0) {
                                    Write-KeyValue "Prereq successfully met: " $description
                                }
                                else {
                                    Write-Host -ForegroundColor Red "Failed to meet prereq: $description"
                                }
                            }
                        }
                        if ($test.executor.elevation_required -and -not $isElevated) {
                            Write-Host -ForegroundColor Red "Elevation required but not provided"
                        }
                    }
                    elseif ($Cleanup) {
                        Write-KeyValue "Executing cleanup for test: " $testId
                        $final_command = Merge-InputArgs $test.executor.cleanup_command $test $InputArgs $PathToAtomicsFolder
                        $res = Invoke-ExecuteCommand $final_command $test.executor.name $TimeoutSeconds
                        Write-KeyValue "Done executing cleanup for test: " $testId
                    }
                    else {
                        Write-KeyValue "Executing test: " $testId
                        $startTime = get-date
                        $final_command = Merge-InputArgs $test.executor.command $test $InputArgs $PathToAtomicsFolder
                        $res = Invoke-ExecuteCommand $final_command $test.executor.name  $TimeoutSeconds
                        Write-ExecutionLog $startTime $AT $testCount $testName $ExecutionLogPath $TimeoutSeconds
                        Write-KeyValue "Done executing test: " $testId
                    }
 
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
        
            if ( ($Force -or $CheckPrereqs -or $ShowDetails -or $ShowDetailsBrief -or $GetPrereqs) -or $psCmdlet.ShouldContinue( 'Do you wish to execute all tests?',
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
# Invoke-AtomicTest t1003 -TestNumbers 13 -GetPrereqs