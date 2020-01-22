# Kill-Tree is based on code from https://stackoverflow.com/questions/55896492/terminate-process-tree-in-powershell-given-a-process-id
function Invoke-KillProcessTree {
    Param([int]$ppid)
    while ($null -ne ($gcim = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ppid })) {

        $gcim | ForEach-Object { Invoke-KillProcessTree $_.ProcessId; Start-Sleep -Seconds 0.5 }
    }
    Stop-Process -Id $ppid -ErrorAction Ignore
}