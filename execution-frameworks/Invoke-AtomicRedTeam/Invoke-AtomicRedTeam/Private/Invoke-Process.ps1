# The Invoke-Process function is loosely based on code from https://github.com/guitarrapc/PowerShellUtil/blob/master/Invoke-Process/Invoke-Process.ps1
function Invoke-Process {
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$FileName = "PowerShell.exe",

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$Arguments = "",
        
        [Parameter(Mandatory = $false, Position = 2)]
        [string]$WorkingDirectory = "$env:TEMP",

        [Parameter(Mandatory = $false, Position = 3)]
        [Int]$TimeoutSeconds = 120
    )

    end {
        try {
            # new Process
            $process = Start-Process -FilePath $FileName -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -NoNewWindow -PassThru
            $handle = $process.Handle # cache process.Handle, otherwise ExitCode is null from powershell processes

            # wait for complete
            $Timeout = [System.TimeSpan]::FromSeconds(($TimeoutSeconds))
            if (-not $process.WaitForExit($Timeout.TotalMilliseconds)) {
                Write-Host -ForegroundColor Red "Process Timed out after $TimeoutSeconds seconds, use '-TimeoutSeconds' to specify a different timeout"
                Invoke-KillProcessTree $process.id
            }

            if ($IsLinux -or $IsMacOS) {
                Start-Sleep -Seconds 5 # On nix, the last 4 lines of stdout get overwritten upon return so pause for a bit to ensure user can view results
            }
            
            # Get Process result 
            return $process.ExitCode
        }
        finally {
            if ($null -ne $process) { $process.Dispose() }
        }
    }
}
