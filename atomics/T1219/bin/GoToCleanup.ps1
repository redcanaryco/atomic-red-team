# GoTo Opener - delete registry install key because it can't be called by the system
$InstalledApp = "GoTo Opener"
$Keys = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -ErrorAction SilentlyContinue
$Items = $Keys | Get-ItemProperty | where-object {$_.DisplayName -eq $InstalledApp}
If ($Items) {
    $KeyToDelete = $Items.PSPath
    Remove-Item $KeyToDelete -Recurse -Force -ErrorAction SilentlyContinue
}
# GoTo Opener - delete user directories
Get-ChildItem "C:\Users\*\AppData" "GoTo Opener" -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $Directory = $_.ToString()
    Remove-Item $Directory -Recurse -Force -ErrorAction SilentlyContinue
    }
Start-Process -FilePath "C:\Program Files (x86)\GoToAssist Remote Support Expert\1702\g2ax_uninstaller_expert.exe" -ArgumentList "/uninstall /silent" -Wait -PassThru | Out-Null
