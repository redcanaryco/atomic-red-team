function Invoke-WebRequestVerifyHash ($url, $outfile, $hash) {
    $success = $false
    $null = @( 
        New-Item -ItemType Directory (Split-Path $outfile) -Force | Out-Null
        $ms = New-Object IO.MemoryStream
        (New-Object System.Net.WebClient).OpenRead($url).copyto($ms)
        $ms.seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
        $actualHash = (Get-FileHash -InputStream $ms).Hash 
        if ( $hash -eq $actualHash) {
            $ms.seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
            $fileStream = New-Object IO.FileStream $outfile, ([System.IO.FileMode]::Create)
            $ms.CopyTo($fileStream);
            $fileStream.Close()
            $success = $true
        }
        else {
            Write-Host -ForegroundColor red "File hash mismatch, expected: $hash, actual: $actualHash" 
        }
    )
    $success
}