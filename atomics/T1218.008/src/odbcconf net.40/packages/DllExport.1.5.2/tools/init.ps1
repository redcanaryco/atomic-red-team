param($installPath, $toolsPath, $package, $project)

# init.ps1 - once for serial install/remove

Import-Module (Join-Path $toolsPath DllExportCmdLets.psm1)

# TODO: required for 'Load-Configurator'
$cecil = [System.Reflection.Assembly]::Load([System.IO.File]::ReadAllBytes("$toolsPath\Mono.Cecil.dll"));