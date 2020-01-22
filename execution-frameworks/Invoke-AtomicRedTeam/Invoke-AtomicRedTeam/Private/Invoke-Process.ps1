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
        [string]$WorkingDirectory = ".",

        [Parameter(Mandatory = $false, Position = 3)]
        [Integer]$TimeoutSeconds = 120
    )

    end {
        try {
            # new Process
            $process = Start-Process -FilePath $FileName -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -NoNewWindow -PassThru
            $handle = $process.Handle # cache process.Handle, otherwise ExitCode is null from powershell processes

            # wait for complete
            $Timeout = [System.TimeSpan]::FromSeconds(($TimeoutSeconds))
            if (-not $process.WaitForExit($Timeout.TotalMilliseconds)) {
                Invoke-KillProcessTree $process.id
            }

            # Get Process result 
            return $process.ExitCode
        }
        finally {
            if ($null -ne $process) { $process.Dispose() }
            if ($null -ne $stdEvent) { $stdEvent.StopJob(); $stdEvent.Dispose() }
            if ($null -ne $errorEvent) { $errorEvent.StopJob(); $errorEvent.Dispose() }
        }
    }
}
