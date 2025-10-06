param (
    [switch]$remove = $false
)

$WHCCName = "Windows Hello Camera Control"
Stop-ScheduledTask -TaskName $WHCCName -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $WHCCName -Confirm:$false -ErrorAction SilentlyContinue

if ($remove) { exit 0 }

$WHCCPrincipal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId "SYSTEM" -LogonType ServiceAccount
$WHCCAction = New-ScheduledTaskAction -Execute "powershell" -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File .\whcc.ps1" -WorkingDirectory $pwd.Path
$WHCCSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
$WHCCTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName $WHCCName -Principal $WHCCPrincipal -Action $WHCCAction -Description $WHCCName -Settings $WHCCSettings -Trigger $WHCCTrigger
Start-ScheduledTask -TaskName $WHCCName