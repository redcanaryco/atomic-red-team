<#
.SYNOPSIS
    Confirms and imports Invoke-AtomicRedTeam dependencies
.DESCRIPTION
    Confirms and imports Invoke-AtomicRedTeam dependencies.  You can specify an alternative ModulePath of powershell-yaml module.
.EXAMPLE Default Confirm-Dependencies
    PS/> Confirm-Dependencies
.EXAMPLE Specify ModulePath of powershell-yaml module
    PS/> Confirm-Dependencies -ModulePath C:\some\path\to\module\powershell-yaml.psm1
.NOTES
    Create Atomic Tests from yaml files described in Atomic Red Team. https://github.com/redcanaryco/atomic-red-team
.LINK
    Blog: http://subt0x11.blogspot.com/2018/08/invoke-atomictest-automating-mitre-att.html
    Github repo: https://github.com/redcanaryco/atomic-red-team
#>
function Confirm-Dependencies {
    [CmdletBinding(DefaultParameterSetName = 'dependencies',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium')]
    Param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'dependencies')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModulePath
    )
    
    Write-Verbose -Message 'Checking whether powershell-yaml is installed'

    try {
        if ($PSBoundParameters.ContainsKey('ModulePath')) {
            Import-Module $ModulePath 
        }
        else {
            Write-Error -ErrorRecord $Error[0] -RecommendedAction 'Could not import the provided module.  Please ensure you can access the ModulePath location.' -ErrorAction Stop
        }
        
        if (-not(Get-Module -Name 'powershell-yaml' -ListAvailable)) {
            if ($pscmdlet.ShouldProcess("PowerShell-Yaml Module", "Install required module")) {
                Install-Module -Name powershell-yaml -Force
                Write-Verbose -Message 'Successfully installed powershell-yaml module'

                Write-Verbose -Message 'Importing powershell-yaml module'
                Import-Module -Name powershell-yaml -Force
            }
        }
    }
    catch {
        Write-Error -ErrorRecord $Error[0] -RecommendedAction 'Please install powershell-yaml before continuing' -ErrorAction Stop
    }
}