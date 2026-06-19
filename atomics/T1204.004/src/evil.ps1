$encoded = "VwByAGkAdABlAC0ASABvAHMAdAAgACIASABlAGwAbABvACAAVwBvAHIAbABkACIAOwAgAFMAdABhAHIAdAAtAFMAbABlAGUAcAAgAC0AUwBlAGMAbwBuAGQAcwAgADMAMwA="
$decoded = [System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($encoded))
iex $decoded
