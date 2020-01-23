function Invoke-KillProcessTree {
    Param([int]$ppid)
    if ($IsLinux -or $IsMacOS) {
        sh -c pkill -9 -P $ppid
    }
    else {
        while ($null -ne ($gcim = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ppid })) {
            $gcim | ForEach-Object { Invoke-KillProcessTree $_.ProcessId; Start-Sleep -Seconds 0.5 }
        }
        Stop-Process -Id $ppid -ErrorAction Ignore
    }
}