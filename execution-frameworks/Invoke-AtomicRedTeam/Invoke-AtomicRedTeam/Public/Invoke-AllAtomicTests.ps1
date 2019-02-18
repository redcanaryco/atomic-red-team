<#
.SYNOPSIS
    Invokes all Atomic test(s)
.DESCRIPTION
    Invokes all Atomic tests(s).  Optionally, you can specify if you want to generate all Atomic test(s) only.
.EXAMPLE Invokes Atomic Test
    PS/> Invoke-AllAtomicTests
	PS/> Invoke-AllAtomicTests -Force
.EXAMPLE Generate All Atomic Tests
    PS/> Invoke-AllAtomicTests -GenerateOnly
.PARAMETER Path
	Path to atomics folder, example C:\AtomicRedTeam\atomics
.PARAMETER GenerateOnly
    Generate tests only do not execute. Writes test commands to STDOUT
.PARAMETER Force
    Override safety handler. Normally this will prompt you to confirm all tests. This will override that.
.NOTES
    Create Atomic Tests from yaml files described in Atomic Red Team. https://github.com/redcanaryco/atomic-red-team
.LINK
    Github repo: https://github.com/redcanaryco/atomic-red-team
#>
function Invoke-AllAtomicTests {
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
        [System.String]
        $Path,

        [Parameter(Mandatory = $false,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'technique')]
        [switch]
        $GenerateOnly,

		[switch]
		$Force
    )
	$InformationPreference = 'Continue'

	function Invoke-AllTests()
	{

		[System.Collections.HashTable]$AllAtomicTests = @{}
		$AtomicFilePath = $Path
		Get-ChildItem $AtomicFilePath -Recurse -Filter *.yaml -File | ForEach-Object {
		$currentTechnique = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
		$parsedYaml = (ConvertFrom-Yaml (Get-Content $_.FullName -Raw ))
		$AllAtomicTests.Add($currentTechnique, $parsedYaml);
		}
		if($GenerateOnly)
		{
			$AllAtomicTests.GetEnumerator() | Foreach-Object { Invoke-AtomicTest $_.Value -GenerateOnly }

		}
		else
		{
			$AllAtomicTests.GetEnumerator() | Foreach-Object { Invoke-AtomicTest $_.Value }
		}

	}

	if ( $Force -or $psCmdlet.ShouldContinue( 'Do you wish to execute all tests?',
                 "Highway to the danger zone, Executing All Atomic Tests!" ) )
	{
		Invoke-AllTests
	}



}
