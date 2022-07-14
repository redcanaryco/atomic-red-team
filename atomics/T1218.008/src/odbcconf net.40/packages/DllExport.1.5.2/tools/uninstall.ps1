param($installPath, $toolsPath, $package, $project)

$assemblyFName      = 'DllExport'
$targetFileName     = 'net.r_eg.DllExport.targets'
$metaLib            = $([System.IO.Path]::Combine("$installPath", 'lib\net20', $assemblyFName + '.dll'));
$gpc                = Get-MBEGlobalProjectCollection
$projects           = $gpc.GetLoadedProjects($project.FullName)

# Configurator

# $dllConf = Get-TempPathToConfiguratorIfNotLoaded 'net.r_eg.DllExport.Configurator.dll' "$toolsPath"
# if($dllConf) {
#     Import-Module $dllConf; 
# }

Import-Module (Load-Configurator "$toolsPath")
Reset-Configuration -MetaLib "$metaLib" -InstallPath "$installPath" -ToolsPath "$toolsPath" -ProjectDTE $project -ProjectsMBE $gpc;

#

return $projects |  % {
    $currentProject = $_

    $currentProject.Xml.Imports | ? {
        $targetFileName -ieq [System.IO.Path]::GetFileName($_.Project)
    }  | % {  
        $currentProject.Xml.RemoveChild($_)
    }
}