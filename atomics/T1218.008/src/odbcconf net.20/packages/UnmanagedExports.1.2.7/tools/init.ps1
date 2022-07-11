param($installPath, $toolsPath, $package, $project)

Import-Module (Join-Path $toolsPath DllExportCmdLets.psm1)

if($project) {
	Assert-PlatformTargetOfProject $project.FullName
}
else {
	Get-AllDllExportMsBuildProjects | % { 
		Assert-PlatformTargetOfProject $_.FullPath 
	}
}