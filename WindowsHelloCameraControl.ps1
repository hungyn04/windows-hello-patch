# Windows Hello Face ID Camera Control Script
# This script monitors for Windows Hello Face ID activity and controls the front camera access

# Requires Administrator privileges
#Requires -RunAsAdministrator

# Configuration
$logFile = "$env:TEMP\WindowsHelloCameraControl.log"
$checkInterval = 1000  # Check every 1 second (in milliseconds)

# Function to write to log
function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

# Function to get front camera device
function Get-FrontCameraDevice {
    try {
        $frontCamera = Get-PnpDevice -Class Camera -Status OK | Where-Object {
            $_.FriendlyName -match "Front|Integrated" -and
            $_.FriendlyName -notmatch "Hello|IR|Infrared"
        }
        return $frontCamera
    }
    catch {
        Write-Log "Error getting front camera device: $($_.Exception.Message)"
        return $null
    }
}

# Function to disable camera device
function Disable-CameraDevice {
    param($device)
    try {
        Disable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
        Write-Log "Disabled camera: $($device.FriendlyName)"
    }
    catch {
        Write-Log "Failed to disable camera $($device.FriendlyName): $($_.Exception.Message)"
    }
}

# Function to enable camera device
function Enable-CameraDevice {
    param($device)
    try {
        Enable-PnpDevice -InstanceId $device.InstanceId -Confirm:$false
        Write-Log "Enabled camera: $($device.FriendlyName)"
    }
    catch {
        Write-Log "Failed to enable camera $($device.FriendlyName): $($_.Exception.Message)"
    }
}

# Function to check if Windows Hello Face ID is active
function Test-WindowsHelloFaceIDActive {
    try {
        # Check for Windows Hello related processes
        $helloProcesses = Get-Process | Where-Object {
            $_.ProcessName -match "WinBio|AuthHost|LogonUI|dwm" -or
            $_.MainWindowTitle -match "Windows Hello|Face ID|Sign-in"
        }

        # Check for lock screen state
        $lockScreenActive = $false
        try {
            $lockScreenActive = (Get-Process -Name "LogonUI" -ErrorAction SilentlyContinue) -ne $null
        }
        catch { }

        # Check for authentication UI
        $authUIActive = $false
        try {
            $authUIActive = (Get-Process -Name "AuthHost" -ErrorAction SilentlyContinue) -ne $null
        }
        catch { }

        # Check for CredentialUIBroker
        try {
            $creUIBrkrActive = (Get-Process -Name "CredentialUIBroker" -ErrorAction SilentlyContinue) -ne $null
        }
        catch { }

        return $lockScreenActive -or $authUIActive -or $creUIBrkrActive
    }
    catch {
        Write-Log "Error checking Windows Hello status: $($_.Exception.Message)"
        return $false
    }
}

# Main monitoring function
function Start-CameraMonitoring {
    Write-Log "Starting Windows Hello Face ID camera monitoring..."

    # Get initial front camera device
    $frontCamera = Get-FrontCameraDevice
    if (-not $frontCamera) {
        Write-Log "No front camera device found. Exiting."
        return
    }

    Write-Log "Found front camera device: $($frontCamera.FriendlyName)"

    $wasHelloActive = $false

    while ($true) {
        try {
            $isHelloActive = Test-WindowsHelloFaceIDActive

            if ($isHelloActive -and -not $wasHelloActive) {
                Write-Log "Windows Hello Face ID activity detected - disabling front camera"
                Disable-CameraDevice $frontCamera
                $wasHelloActive = $true
            }
            elseif (-not $isHelloActive -and $wasHelloActive) {
                Write-Log "Windows Hello Face ID activity ended - enabling front camera"
                Enable-CameraDevice $frontCamera
                $wasHelloActive = $false
            }

            Start-Sleep -Milliseconds $checkInterval
        }
        catch {
            Write-Log "Error in monitoring loop: $($_.Exception.Message)"
            Start-Sleep -Milliseconds $checkInterval
        }
    }
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Main execution
try {
    if (-not (Test-Administrator)) {
        Write-Host "This script requires Administrator privileges to control camera devices."
        Write-Host "Please run PowerShell as Administrator and try again."
        exit 1
    }

    Write-Log "Windows Hello Face ID Camera Control Script started"
    Write-Log "Log file: $logFile"
    Write-Log "Check interval: $checkInterval ms"

    # Start monitoring
    Start-CameraMonitoring
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)"
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
