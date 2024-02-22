function Invoke-MalDoc {
    <#
    .SYNOPSIS
    A module to programatically execute Microsoft Word and Excel Documents containing macros.

    .DESCRIPTION
    A module to programatically execute Microsoft Word and Excel Documents containing macros. The module will temporarily add a registry key to allow PowerShell to interact with VBA.
    .PARAMETER macroCode
    [Required] The VBA code to be executed. By default, this macro code will be wrapped in a sub routine, called "Test" by default. If you don't want your macro code to be wrapped in a subroutine use the `-noWrap` flag. To specify the subroutine name use the `-sub` parameter.
    .PARAMETER macroFile
    [Required] A file containing the VBA code to be executed. To specify the subroutine name to be called use the `-sub` parameter.
    .PARAMETER officeVersion
    [Optional] The Microsoft Office version to use for executing the document. e.g. "16.0". The version will be determined Programmatically if not specified.
    .PARAMETER officeProduct
    [Required] The Microsoft Office application in which to create and execute the macro, either "Word" or "Excel".
    .PARAMETER sub
    [Optional] The name of the subroutine in the macro code to call for execution. Also the name of the subroutine to wrap the supplied `macroCode` in if `noWrap` is not specified.
    .PARAMETER noWrap
    [Optional] A switch that specifies that the supplied `macroCode` should be used as-is and not wrapped in a subroutine.
    
    .EXAMPLE
    C:\PS> Invoke-Maldoc -macroCode "MsgBox `"Hello`"" -officeProduct "Word"
    -----------
    Create a macro enabled Microsoft Word Document. The macro code `MsgBox "Hello"` will be wrapped inside of a subroutine call "Test" and then executed.
    
    .EXAMPLE
    C:\PS> $macroCode = Get-Content path/to/macro.txt -Raw
    C:\PS> Invoke-Maldoc -macroCode $macroCode -officeProduct "Word"
    -----------
    Create a macro enabled Microsoft Word Document. The macro code read from `path/to/macro.txt` will be wrapped inside of a subroutine call "Test" and then executed.
    
    .EXAMPLE
    C:\PS> Invoke-Maldoc -macroCode "MsgBox `"Hello`"" -officeProduct "Excel" -sub "DoIt"
    -----------
    Create a macro enabled Microsoft Excel Document. The macro code `MsgBox "Hello"` will be wrapped inside of a subroutine call "DoIt" and then executed.

    .EXAMPLE
    C:\PS> Invoke-Maldoc -macroCode "Sub Exec()`nMsgBox `"Hello`"`nEnd Sub" -officeProduct "Word" -noWrap -sub "Exec"
    -----------
    Create a macro enabled Microsoft Word Document. The macroCode will be unmodified (i.e. not wrapped insided a subroutine) and the "Exec" subroutine will be executed.

    .EXAMPLE
    C:\PS> Invoke-Maldoc -macroFile "C:\AtomicRedTeam\atomics\T1003\src\macro.txt" -officeProduct "Word" -sub "DoIt"
    -----------
    Create a macro enabled Microsoft Word Document. The macroCode will be read from the specified file and the "DoIt" subroutine will be executed.

#>

    Param(
        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = "code")]
        [String]$macroCode,

        [Parameter(Position = 0, Mandatory = $True, ParameterSetName = "file")]
        [String]$macroFile,

        [Parameter(Position = 1, Mandatory = $False)]
        [String]$officeVersion,

        [Parameter(Position = 2, Mandatory = $True)]
        [ValidateSet("Word", "Excel")]
        [String]$officeProduct,

        [Parameter(Position = 3, Mandatory = $false)]
        [String]$sub = "Test",

        [Parameter(Position = 4, Mandatory = $false, ParameterSetName = "code")]
        [switch]$noWrap
    )

    $app = New-Object -ComObject "$officeProduct.Application"
    if (-not $officeVersion) { $officeVersion = $app.Version } 
    $Key = "HKCU:\Software\Microsoft\Office\$officeVersion\$officeProduct\Security\"
    if (-not (Test-Path $key)) { New-Item $Key }
    Set-ItemProperty -Path $Key -Name 'AccessVBOM' -Value 1

    if ($macroFile) {
        $macroCode = Get-Content $macroFile -Raw
    }
    elseif (-not $noWrap) {
        $macroCode = "Sub $sub()`n" + $macroCode + "`nEnd Sub"
    }

    if ($officeProduct -eq "Word") {
        $doc = $app.Documents.Add()
    }
    else {
        $doc = $app.Workbooks.Add()
    }
    $comp = $doc.VBProject.VBComponents.Add(1)
    $comp.CodeModule.AddFromString($macroCode)
    $app.Run($sub)
    $doc.Close(0)
    $app.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($comp) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($app) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$officeVersion\$officeProduct\Security\" -Name 'AccessVBOM' -ErrorAction Ignore
}