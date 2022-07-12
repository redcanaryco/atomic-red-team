param($installPath, $toolsPath, $package, $project)

$targetFileName = 'RGiesecke.DllExport.targets'
$targetFileName = [System.IO.Path]::Combine($toolsPath, $targetFileName)
$targetUri = New-Object Uri($targetFileName, [UriKind]::Absolute)

$projects = Get-DllExportMsBuildProjectsByFullName($project.FullName)

return $projects |  % {
	$currentProject = $_

	$currentProject.Xml.Imports | ? {
		"RGiesecke.DllExport.targets" -ieq [System.IO.Path]::GetFileName($_.Project)
	}  | % {  
		$currentProject.Xml.RemoveChild($_)
	}
}