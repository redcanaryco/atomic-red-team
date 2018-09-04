Requires Installation of PowerShell-Yaml

https://github.com/cloudbase/powershell-yaml

Basic usage Examples:

- Load PowerShell Script:
    `. C:\AtomicRedTeam\execution-frameworks\Invoke-AtomicRedTeam\Invoke-AtomicRedTeam.ps1`

- Execute Single Test:

   `$T1117 = Get-AtomicTechnique -Path ..\..\atomics\T1117\T1117.yaml`  
   `Invoke-AtomicTest $T1117`  

- Generate All Tests

    `[System.Collections.HashTable]$AllAtomicTests = @{};`  
    `$AtomicFilePath = 'C:\AtomicRedTeam\atomics\';`  
    `Get-Childitem $AtomicFilePath -Recurse -Filter *.yaml -File | ForEach-Object {`  
    `$currentTechnique = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName);`  
    `$parsedYaml = (ConvertFrom-Yaml (Get-Content $_.FullName -Raw ));`  
    `$AllAtomicTests.Add($currentTechnique, $parsedYaml);`  
    `$AllAtomicTests.GetEnumerator() | %{ Invoke-Atomic $_.Value -GenerateOnly}`

- Feedback Welcome
