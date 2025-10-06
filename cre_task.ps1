$WHCCName = "Windows Hello Camera Control"
$WHCCPrincipal = New-ScheduledTaskPrincipal -RunLevel Highest -UserId "SYSTEM" -LogonType ServiceAccount
$WHCCAction = New-ScheduledTaskAction -Execute "powershell" -Argument "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File .\whcc.ps1" -WorkingDirectory $pwd.Path
$WHCCSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -DontStopIfGoingOnBatteries -ExecutionTimeLimit "PT0S"
$WHCCTrigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName $WHCCName -Principal $WHCCPrincipal -Action $WHCCAction -Description $WHCCName -Settings $WHCCSettings -Trigger $WHCCTrigger
Start-ScheduledTask -TaskName $WHCCName