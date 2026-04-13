function Set-AzureAuthentication {
    param (
        [string]$TenantID,
        [string]$ClientID,
        [string]$ClientSecret,
        [string]$Environment
    )
    $SecurePassword = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientID, $SecurePassword

    $null = Connect-AzAccount -ServicePrincipal -TenantId $TenantID -Credential $Credential -Environment $Environment -WarningAction:SilentlyContinue
}

function Get-AzureDiscoveryData {
    param(
        [string]$Environment,
        [string]$OutputDirectory
    )

    if (-not (Test-Path $OutputDirectory)) {
        $null = New-Item -ItemType Directory -Path $OutputDirectory
    }
    # Subscription Discovery
    "SubscriptionID" | Out-File -FilePath $OutputDirectory/subscriptions.csv
    $subscriptions = Get-AzureSubscriptions
    $subscriptions | Out-File $OutputDirectory/subscriptions.csv -Append
    $subscriptions = $subscriptions -split "`n"
    # VM Discovery
    "Name,Id,PublicIP,Size" | Out-File -FilePath $OutputDirectory/vms.csv
    Get-AzureVMDiscovery -Subscriptions $subscriptions | Out-File $OutputDirectory/vms.csv -Append
    # Storage Account Discovery
    "Name,ResourceGroup,Location" | Out-File -FilePath $OutputDirectory/storage.csv
    Get-AzureStorageDiscovery -Subscriptions $subscriptions | Out-File $OutputDirectory/storage.csv -Append
    # Key Vault Discovery
    "Name,ResourceGroup,Location" | Out-File -FilePath $OutputDirectory/keyvaults.csv
    Get-AzureKeyVaultDiscovery -Subscriptions $subscriptions | Out-File $OutputDirectory/keyvaults.csv -Append

    Write-Host "Discovery data saved to $OutputDirectory"
}

function Get-AzureSubscriptions {
    $subscriptions = Get-AzSubscription | Select-Object -ExpandProperty Id
    foreach ($subscription in $subscriptions) {
        $output += "$subscription`n"
    }
    if ($null -ne $output) {
        $output = $output.Substring(0, $output.Length - 1)
    }
    return $output
}

function Get-AzureVMDiscovery {
    param (
        [string[]]$Subscriptions
    )
    foreach ($subscription in $subscriptions) {
        $null = Set-AzContext -Subscription $subscription
        $vms = Get-AzVM
        foreach ($vm in $vms) {
            $vmName = $vm.Name
            $vmId = $vm.Id
            $nicId = ($vm | Select-Object -ExpandProperty NetworkProfile).NetworkInterfaces[0].Id
            $pipId = (Get-AzNetworkInterface -ResourceId $nicId | Select-Object -ExpandProperty IpConfigurations | Select-Object -ExpandProperty PublicIpAddress).Id
            $pipName = ($pipId -split "/")[-1]
            $vmPublicIP = (Get-AzPublicIpAddress -Name $pipName).IpAddress
            $vmSize = $vm.HardwareProfile.VmSize
            $output += "$vmName,$vmId,$vmPublicIP,$vmSize`n"
        }
        if ($null -ne $output) {
            $output = $output.Substring(0, $output.Length - 1)
        }
    }
    return $output
}

function Get-AzureStorageDiscovery {
    param (
        [string[]]$Subscriptions
    )
    foreach ($subscription in $subscriptions) {
        $null = Set-AzContext -Subscription $subscription
        $storageAccounts = Get-AzStorageAccount
        foreach ($storageAccount in $storageAccounts) {
            $storageAccountName = $storageAccount.StorageAccountName
            $resourceGroup = $storageAccount.ResourceGroupName
            $location = $storageAccount.Location
            $output += "$storageAccountName,$resourceGroup,$location`n"
        }
        if ($null -ne $output) {
            $output = $output.Substring(0, $output.Length - 1)
        }
    }
    return $output
}

function Get-AzureKeyVaultDiscovery {
    param (
        [string[]]$Subscriptions
    )
    foreach ($subscription in $subscriptions) {
        $null = Set-AzContext -Subscription $subscription
        $keyVaults = Get-AzKeyVault
        foreach ($keyVault in $keyVaults) {
            $keyVaultName = $keyVault.VaultName
            $resourceGroup = $keyVault.ResourceGroupName
            $location = $keyVault.Location
            $output += "$keyVaultName,$resourceGroup,$location`n"
        }
        if ($null -ne $output) {
            $output = $output.Substring(0, $output.Length - 1)
        }
    }
    return $output
}

function Remove-BlankFiles {
    param (
        [string]$OutputDirectory
    )
    $files = Get-ChildItem -Path $OutputDirectory
    foreach ($file in $files) {
        $lineCount = (Get-Content -Path $file.FullName).Count
        if ($lineCount -eq 1) {
            $null = Remove-Item -Path $file.FullName
        }
    }
}
