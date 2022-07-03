param($installPath, $toolsPath, $package, $project)

$targetFileName     = 'net.r_eg.DllExport.targets'
$assemblyFName      = 'DllExport' # $package.AssemblyReferences[0].Name
$publicKeyToken     = '8337224C9AD9E356';
$metaLib            = $([System.IO.Path]::Combine("$installPath", 'lib\net20', $assemblyFName + '.dll'));
$targetFileName     = [IO.Path]::Combine($toolsPath, $targetFileName)
$targetUri          = New-Object Uri -ArgumentList $targetFileName, [UriKind]::Absolute
$gpc                = Get-MBEGlobalProjectCollection
$projects           = $gpc.GetLoadedProjects($project.FullName)

# GUI Configurator

# powershell -Command "Import-Module (Join-Path $escToolsPath Configurator.dll); Set-Configuration -Dll $asmpath"

# $dllConf = Get-TempPathToConfiguratorIfNotLoaded 'net.r_eg.DllExport.Configurator.dll' "$toolsPath"
# if($dllConf) {
#     Import-Module $dllConf; 
# }

Import-Module (Load-Configurator "$toolsPath")
Set-Configuration -MetaLib "$metaLib" -InstallPath "$installPath" -ToolsPath "$toolsPath" -ProjectDTE $project -ProjectsMBE $gpc;


# change the reference to DllExport.dll to not be copied locally

$project.Object.References | ? { 
    $_.Name -ieq $assemblyFName -And $_.PublicKeyToken -ieq $publicKeyToken
} | % {
    if($_ | Get-Member | ? {$_.Name -eq "CopyLocal"}){
        $_.CopyLocal = $false
    }
}

$projects |  % {
    $currentProject = $_

    # remove imports of net.r_eg.DllExport.targets from this project 
    $currentProject.Xml.Imports | ? {
        return ($targetFileName -ieq [IO.Path]::GetFileName($_.Project))
    }  | % {  
        $currentProject.Xml.RemoveChild($_);
    }

    # remove the properties DllExportAttributeFullName and DllExportAttributeAssemblyName
    $currentProject.Xml.Properties | ? {
        $_.Name -eq "DllExportAttributeFullName" -or $_.Name -eq "DllExportAttributeAssemblyName"
    } | % {
        $_.Parent.RemoveChild($_)
    }

    $projectUri = New-Object Uri -ArgumentList $currentProject.FullPath, [UriKind]::Absolute
    $relativeUrl = $projectUri.MakeRelative($targetUri)
    $import = $currentProject.Xml.AddImport($relativeUrl)
    $import.Condition = "Exists('$relativeUrl')";
    
    # remove the old stuff in the DllExports folder from previous versions, (will check that only known files are in it)
    Remove-OldDllExportFolder $project
}