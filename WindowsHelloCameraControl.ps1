# WindowsHelloCameraControl.ps1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
  Monitors for Windows Hello Face ID activity and toggles the front camera.
#>

# Configuration
$logFile       = "$env:TEMP\WindowsHelloCameraControl.log"
$checkInterval = 1000  # milliseconds

function Write-Log {
    param([string]$Message)
    $ts    = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$ts – $Message"
    Add-Content -Path $logFile -Value $entry
}

function Get-FrontCameraDevice {
    Get-PnpDevice -Class Camera -Status OK |
      Where-Object {
          $_.FriendlyName -match "Front" -and
          $_.FriendlyName -notmatch "Hello|IR|Infrared"
      }
}

function Test-WindowsHelloFaceIDActive {
    # Look for the Hello authentication processes
    $helloProcs = Get-Process -Name AuthHost,LogonUI,WinBio -ErrorAction SilentlyContinue
    return $helloProcs.Count -gt 0
}

# --- Main ---
Write-Log "===== Script started ====="
Write-Log "Logging to $logFile every $checkInterval ms"

$helloWasActive = $false

while ($true) {
    try {
        $isActive = Test-WindowsHelloFaceIDActive
        $cam      = Get-FrontCameraDevice

        if ($cam) {
            if ($isActive -and -not $helloWasActive) {
                Write-Log "Hello ON — disabling camera: $($cam.FriendlyName)"
                Disable-PnpDevice -InstanceId $cam.InstanceId -Confirm:$false
                $helloWasActive = $true
            }
            elseif (-not $isActive -and $helloWasActive) {
                Write-Log "Hello OFF — enabling camera: $($cam.FriendlyName)"
                Enable-PnpDevice  -InstanceId $cam.InstanceId -Confirm:$false
                $helloWasActive = $false
            }
        }
        else {
            Write-Log "No front camera found; retrying..."
        }
    }
    catch {
        Write-Log "Error in monitoring loop: $($_.Exception.Message)"
    }

    Start-Sleep -Milliseconds $checkInterval
}
