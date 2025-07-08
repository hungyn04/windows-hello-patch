sc.exe create CameraControlService `
  binPath= "`"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`" -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"C:\Users\prkha\Scripts\windows-hello-patch\WindowsHelloCameraControl.ps1`"" `
  DisplayName= "Windows Hello Camera Control" `
  start= auto
