<#
.SYNOPSIS
    Get Atomic Technique
.DESCRIPTION
    Gets Atomic Technique(s) based on the provided path
.EXAMPLE Get Atomic Technique
    PS/> $T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml
.NOTES
    Create Atomic Tests from yaml files described in Atomic Red Team. https://github.com/redcanaryco/atomic-red-team
.LINK
    Blog: http://subt0x11.blogspot.com/2018/08/invoke-atomictest-automating-mitre-att.html
    Github repo: https://github.com/redcanaryco/atomic-red-team
#>
function Get-AtomicTechnique {
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
        [string]
        $Path
    )
    Begin { Write-Debug -Message "Getting atomic technique from $Path" }


    Process
    {

        Write-Verbose -Message 'Attempting to convert files from yaml'
        foreach ($file in $Path) {
            if ($pscmdlet.ShouldProcess($file, 'Converting yaml file')) {
                Write-Verbose -Message "Converting $file from Yaml"]
                $parsedYaml = ConvertFrom-Yaml (Get-Content $file -Raw)
                Write-Output $parsedYaml
            }
        }
    }
}
