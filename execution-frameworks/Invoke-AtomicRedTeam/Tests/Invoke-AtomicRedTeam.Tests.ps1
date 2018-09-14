$TemplatePowerShellModule = 'Invoke-AtomicRedTeam'

$here = "$(Split-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -Parent)\$TemplatePowerShellModule"

Describe "$TemplatePowerShellModule PowerShell Module Tests" {
    Context 'Module Setup' {
        It "has the root module $TemplatePowerShellModule.psm1" {
            "$here\$TemplatePowerShellModule.psm1" | Should -Exist
        }
        It "has the manifest file $TemplatePowerShellModule.psd1" {
            "$here\$TemplatePowerShellModule.psd1" | should exist
        }
        It "$TemplatePowerShellModule has functions" {
            "$here\Public\*.ps1" | Should exist
        }
        It "$TemplatePowerShellModule is valid PowerShell Code" {
            $psFile = Get-Content -Path "$here\$TemplatePowerShellModule.psm1" -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.count | Should be 0
        }
    }
}

$pubFunctions = ('Confirm-Dependencies', 'Get-AtomicTechnique', 'Invoke-AtomicTest')

$folders = ( 'Public')

foreach ($folder in $folders) {
    Describe 'Folders Tests' {
        It "$folder should exist" {
            "$here\$Folder" | Should Exist
        }
    }
}

Describe 'Function Tests' {
    foreach ($function in $pubFunctions) {
        Context 'Public Functions' {
            It "$function.ps1 should exist" {
                "$here\Public\$function.ps1" | Should Exist
            }
            It "$function.ps1 should have help block" {
                "$here\Public\$function.ps1" | Should -FileContentMatch '<#'
                "$here\Public\$function.ps1" | Should -FileContentMatch '#>'
            }
            It "$function.ps1 should have a SYNOPSIS section in the help block" {
                "$here\Public\$function.ps1" | Should -FileContentMatch '.SYNOPSIS'
            }
            It "$function.ps1 should have a DESCRIPTION section in the help block" {
                "$here\Public\$function.ps1" | Should -FileContentMatch '.DESCRIPTION'
            }
            It "$function.ps1 should have a EXAMPLE section in the help block" {
                "$here\Public\$function.ps1" | Should -FileContentMatch '.EXAMPLE'
            }
            It "$function.ps1 should be an advanced function" {
                "$here\Public\$function.ps1" | Should -FileContentMatch 'function'
                "$here\Public\$function.ps1" | Should -FileContentMatch 'CmdLetBinding'
                "$here\Public\$function.ps1" | Should -FileContentMatch 'param'
            }
            It "$function.ps1 should contain Write-Verbose blocks" {
                "$here\Public\$function.ps1" | Should -FileContentMatch 'Write-Verbose'
            }
            It "$function.ps1 is valid PowerShell code" {
                $psFile = Get-Content -Path "$here\Public\$function.ps1" -ErrorAction Stop
                $errors = $null
                $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
                $errors.count | Should be 0
            }
        }# Context Public Function Tests
    } # end of Public function foreach
} # end of describe block