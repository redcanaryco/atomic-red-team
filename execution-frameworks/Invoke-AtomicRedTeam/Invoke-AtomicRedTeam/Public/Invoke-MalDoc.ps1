# Maldoc Handler
# This function uses COM objects to emulate the creation and execution of malicious office documents

function Invoke-MalDoc($macro_code, $office_version, $office_product) {
    
    $macro_code = "Sub Test()`n" + $macro_code + "`nEnd Sub"    
    
    if ($office_product -eq "Word") {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$office_version\Word\Security\" -Name 'AccessVBOM' -Value 1
        
        $word = New-Object -ComObject "Word.Application"
        $doc = $word.Documents.Add()
       
        $word.ActiveDocument.VBProject.VBComponents.Add(1)
        $word.VBE.ActiveVBProject.VBComponents.Item("Module1").CodeModule.AddFromString($macro_code)

        $word.Run("Test")
        $doc.Close(0)
    }
    elseif ($office_product -eq "Excel") {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$office_version\Excel\Security\" -Name 'AccessVBOM' -Value 1
        
        $excel = New-Object -ComObject "Excel.Application"
        $excel.Workbooks.Add()
        
        $excel.VBE.ActiveVBProject.VBComponents.Add(1)
        $excel.VBE.ActiveVBProject.VBComponents.Item("Module1").CodeModule.AddFromString($macro_code)
        
        $excel.Run("Test")
        $excel.DisplayAlerts = $False
        $excel.Quit()
    }
    else {
        Write-Host -ForegroundColor Red "$office_product not supported"
    }
}
