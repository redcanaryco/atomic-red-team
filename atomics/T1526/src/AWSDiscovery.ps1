Import-Module AWSPowerShell

function Set-AWSAuthentication {
    param (
        [string]$AccessKey,
        [string]$SecretKey,
        [string]$SessionToken,
        [string]$Regions,
        [string]$AWSProfile
    )

    if ($SessionToken -eq "" -and $AWSProfile -eq "") {
        Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs "atomic"
    }
    elseif ($SessionToken -ne "" -and $AWSProfile -ne "") {
        Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -SessionToken $SessionToken -StoreAs "atomic" 
    }
    elseif ($AWSProfile -ne "") {
        Set-AWSCredential -ProfileName $AWSProfile -StoreAs "atomic"
    }
}

function Get-AWSDiscoveryData {
    param(
        [string]$OutputDirectory,
        [string]$Regions
    )

    if (-not (Test-Path $OutputDirectory)) {
        $null = New-Item -ItemType Directory -Path $OutputDirectory
    }
    # Account Discovery
    "AccountID" | Out-File -FilePath $OutputDirectory/account.csv
    Get-AWSAccountInfo | Out-File $OutputDirectory/account.csv -Append
    # EC2 Discovery
    "Name,Id,PublicIP,Size" | Out-File -FilePath $OutputDirectory/instances.csv
    foreach ($region in $Regions.Split(",")) {
        Get-EC2Discovery -Region $region | Out-File $OutputDirectory/instances.csv -Append
    }
    # S3 Bucket Discovery
    "BucketName,CreationDate" | Out-File -FilePath $OutputDirectory/buckets.csv
    Get-S3BucketDiscovery | Out-File $OutputDirectory/buckets.csv -Append
    # IAM User Discovery
    "UserName,CreateDate,PasswordLastUsed" | Out-File -FilePath $OutputDirectory/users.csv
    Get-IAMUserDiscovery | Out-File $OutputDirectory/users.csv -Append

    Write-Host "Discovery data saved to $OutputDirectory"
}

function Get-AWSAccountInfo {
    $account = Get-STSCallerIdentity
    $accountID = $account.Account
    return $accountID
}

function Get-EC2Discovery {
    param(
        [string]$Region
    )
    Set-DefaultAWSRegion -Region $region
    $instances = Get-EC2Instance | Select-Object -ExpandProperty Instances
    $output = $null
    foreach($instance in $instances) {
        $instanceName = $instance.Tags | Where-Object { $_.Key -eq "Name" } | Select-Object -ExpandProperty Value
        $instanceId = $instance.InstanceId
        $instancePublicIp = $instance.PublicIpAddress
        $instanceSize = $instance.InstanceType
        $output += "$instanceName,$instanceId,$instancePublicIp,$instanceSize,$Region`n"
    }
    if ($null -ne $output) {
        $output = $output.Substring(0, $output.Length - 1)
    }
    return $output
}

function Get-S3BucketDiscovery {
    $buckets = Get-S3Bucket
    foreach($bucket in $buckets) {
        $bucketName = $bucket.BucketName
        $creationDate = $bucket.CreationDate
        $output += "$bucketName,$creationDate`n"
    }
    if ($null -ne $output) {
        $output = $output.Substring(0, $output.Length - 1)
    }
    return $output
}

function Get-IAMUserDiscovery {
    $users = Get-IAMUser
    foreach($user in $users) {
        $userName = $user.UserName
        $createDate = $user.CreateDate
        $passwordLastUsed = $user.PasswordLastUsed
        $output += "$userName,$createDate,$passwordLastUsed`n"
    }
    if ($null -ne $output) {
        $output = $output.Substring(0, $output.Length - 1)
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
