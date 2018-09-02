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

.EXAMPLE
Convert Single Yaml File to Technique Object
$T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
.EXAMPLE
Get the Atomic Tests For A Given Technique
Get-AtomicTest $T1117

.NOTES
This script converts Atomic Tests Expressed in YAML into PowerShell Objects.

.LINK
Blog: http://subt0x11.blogspot.com/2018/08/invoke-atomictest-automating-mitre-att.html
Github repo: https://github.com/redcanaryco/atomic-red-team

#>

function Get-AtomicTechnique {
[CmdletBinding()]
Param(

	[string]
	$Path
)
# Returns A HashTable For Each File Passed In
BEGIN { }
PROCESS {
		foreach ($File in $Path)
		{
			$parsedYaml = (ConvertFrom-Yaml (Get-Content $File -Raw ))
			Write-Output $parsedYaml
		}
}
END { }

}

function Get-AtomicTest{
[CmdletBinding()]
Param(
	[System.Collections.Hashtable]
	$AtomicTechnique
)
BEGIN{}
PROCESS {
	foreach ($Technique in $AtomicTechnique)
	{

		$AtomicTest = $Technique.atomic_tests

		foreach ($Test in $AtomicTest)
		{
			#Only Process Windows Tests For Now
			if ( !($Test.supported_platforms.Contains('windows')) ){ return }

			#Reject Manual Tests
			if ( ($Test.executor.name.Contains('manual')) ) 	{ return }
			Write-Host "[********BEGIN TEST*******]`n" $Technique.display_name.ToString(), $Technique.attack_technique.ToString() "has" $Technique.atomic_tests.Count "Test(s)"  -Foreground Yellow
			Write-Host $Test.name.ToString()
			Write-Host $Test.description.ToString()

			$finalCommand = $Test.executor.command
			if($Test.input_arguments.Count -gt 0)
			{
				$InputArgs = [Array]($Test.input_arguments.Keys).Split(" ")
				$InputDefaults = [Array]( $Test.input_arguments.Values | %{$_.default }).Split(" ")

				for($i = 0; $i -lt $InputArgs.Length; $i++)
				{
					$findValue = '#{' + $InputArgs[$i] + '}'
					$finalCommand = $finalCommand.Replace( $findValue, $InputDefaults[$i] )
				}
				Write-Output $finalCommand
			}
			else
			{
				Write-Output $finalCommand
			}

		}

		Write-Host "[!!!!!!!!END TEST!!!!!!!]`n"


	}
}
END {}

}


function Invoke-AtomicTest{
[CmdletBinding()]
Param(
	[System.Collections.Hashtable]
	$AtomicTechnique
)
BEGIN {}
PROCESS {
	foreach ($Technique in $AtomicTechnique)
		{

			$AtomicTest = $Technique.atomic_tests

			foreach ($Test in $AtomicTest)
			{
				#Only Process Windows Tests For Now
				if ( !($Test.supported_platforms.Contains('windows')) ){ return }

				#Reject Manual Tests
				if ( ($Test.executor.name.Contains('manual')) ) 	{ return }
				Write-Host "[********EXECUTING TEST*******]`n" $Technique.display_name.ToString(), $Technique.attack_technique.ToString()  -Foreground Yellow
				Write-Host $Test.name.ToString()
				Write-Host $Test.description.ToString()

				$finalCommand = $Test.executor.command
				if($Test.input_arguments.Count -gt 0)
				{
					#Fix up, Replace InputArgs
					$InputArgs = [Array]($Test.input_arguments.Keys).Split(" ")
					$InputDefaults = [Array]( $Test.input_arguments.Values | %{$_.default }).Split(" ")

					for($i = 0; $i -lt $InputArgs.Length; $i++)
					{
						$findValue = '#{' + $InputArgs[$i] + '}'
						$finalCommand = $finalCommand.Replace( $findValue, $InputDefaults[$i] )
					}

				}

				#Get Executor and Build Command Script
				switch ($Test.executor.name) {

				"command_prompt" { Write-Host "Command Prompt`n $finalCommand"  -Foreground Green; break }
				"powershell" { Write-Host "PowerShell`n $finalCommand" -Foreground Cyan; break }
				default {"Something else happened"; break}
				}

			}

			Write-Host "[!!!!!!!!END TEST!!!!!!!]`n`n" -Foreground Yellow
		}

}
END {}

}
