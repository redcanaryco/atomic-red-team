function Invoke-ExecuteCommand ($finalCommand, $executor) {
    $null = @( 
        if($null -eq $finalCommand){return 0}
        $finalCommand = $finalCommand.trim()
        Write-Verbose -Message 'Invoking Atomic Tests using defined executor'
        if ($executor -eq "command_prompt" -or $executor -eq "sh" -or $executor -eq "bash") {
            $execCommand = $finalCommand.Replace("`n", " & ")
            $execPrefix = "-c"
            $execExe = $executor
            if ($executor -eq "command_prompt") { $execPrefix = "/c"; $execExe = "cmd.exe" }
            $res = Invoke-Process -filename $execExe -Arguments "$execPrefix `"$execCommand`"" -TimeoutSeconds $TimeoutSeconds                
        }
        elseif ($executor -eq "powershell") {
            $execCommand = $finalCommand -replace "`"", "`\`"`""
            $execExe = "powershell.exe"; if ($IsLinux -or $IsMacOS) { $execExe = "pwsh" }
            $res = Invoke-Process -filename $execExe -Arguments "& {$execCommand}" -TimeoutSeconds $TimeoutSeconds
                      
        }
        else { 
            Write-Warning -Message "Unable to generate or execute the command line properly. Unknown executor"
            $res = -1
        }
    )
    $res
}