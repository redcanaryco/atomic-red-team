function Remove-OldDllExportFolder {
	param($project)
	$defaultFiles = ('DllExportAttribute.cs',
	                 'Mono.Cecil.dll',
	                 'RGiesecke.DllExport.dll',
	                 'RGiesecke.DllExport.pdb',
	                 'RGiesecke.DllExport.MSBuild.dll',
	                 'RGiesecke.DllExport.MSBuild.pdb',
	                 'RGiesecke.DllExport.targets')

	$projectFile = New-Object 'System.IO.FileInfo'($project.FullName)

	$projectFile.Directory.GetDirectories("DllExport") | Select-Object -First 1 | % {
		$dllExportDir = $_
	
		if($dllExportDir.GetDirectories().Count -eq 0){
			$unknownFiles = $dllExportDir.GetFiles() | Select -ExpandProperty Name | ? { -not $defaultFiles -contains $_ }
	
			if(-not $unknownFiles){
				Write-Host "Removing 'DllExport' from " $project.Name
				$project.ProjectItems | ? {	$_.Name -ieq 'DllExport' } | % {
					$_.Remove()
				}

				Write-Host "Deleting " $dllExportDir.FullName " ..."
				$dllExportDir.Delete($true)
			}
		}
	}
}

function Remove-OldDllExportFolders {
	Get-Project -all | % {
		Remove-OldDllExportFolder $_
	}
}

function Get-DllExportMsBuildProjectsByFullName([String] $fullName) {
	$msBuildV4Name = 'Microsoft.Build, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a';
	$msBuildV4 = [System.Reflection.Assembly]::LoadWithPartialName($msBuildV4Name)

	if(!$msBuildV4) {
		throw New-Object 'System.IO.FileNotFoundException'("Could not load $msBuildV4Name.")
	}

	$projectCollection = $msBuildV4.GetType('Microsoft.Build.Evaluation.ProjectCollection')

	return $projectCollection::GlobalProjectCollection.GetLoadedProjects($fullName)
}

function Get-AllDllExportMsBuildProjects {
	(Get-Project -all | % {
		Get-DllExportMsBuildProjectsByFullName $_.FullName
	}) | ? {
		return ($_.Xml.Imports | ? {
			   "RGiesecke.DllExport.targets" -ieq [System.IO.Path]::GetFileName($_.Project);
		}).Length -gt 0;
	}
}

function Assert-PlatformTargetOfProject([String] $fullName) {
	$proj = Get-DllExportMsBuildProjectsByFullName $fullName

	if(!$proj) {
		return;
	}

	$platformTarget = $proj.GetPropertyValue('PlatformTarget');

	if(!$platformTarget -or ($platformTarget -ine 'x86' -and $platformTarget -ine 'x64')) {
		$projectName = [IO.Path]::GetFileNameWithoutExtension($fullName);
		if(!$platformTarget) {
			$platformTarget = "has no platform target";
		} else {
			$platformTarget = "has a platform target of '$platformTarget'";
		}
		Write-Warning "The project '$projectName' $platformTarget. Only x86 or x64 assemblies can export functions."
		Write-Host ""
	}
}

function Set-NoDllExportsForAnyCpu([String] $projectName, [System.Nullable[bool]] $value) {
    $projects = Get-AllDllExportMsBuildProjects;
    
    [String] $asString = $value;

    if($projectName) {
        $projects = $projects | where { $_.Name -ieq $projectName };
    }
    $propertyName = 'NoDllExportsForAnyCpu';
    
    $projects = $projects | where { 
        $_.GetPropertyValue($propertyName) -ine $asString 
    } | % {
        $_.SetProperty($propertyName, $asString);
    }
}

Export-ModuleMember Set-NoDllExportsForAnyCpu

Export-ModuleMember Remove-OldDllExportFolder
Export-ModuleMember Remove-OldDllExportFolders
Export-ModuleMember Get-DllExportMsBuildProjectsByFullName
Export-ModuleMember Get-AllDllExportMsBuildProjects
Export-ModuleMember Assert-PlatformTargetOfProject