# Camera Device Identification Script
# This script lists all camera devices to help identify your front camera

Write-Host "=== Camera Device Identification ===" -ForegroundColor Green
Write-Host ""

try {
    # Get all camera devices
    $cameras = Get-PnpDevice -Class Camera
    
    if ($cameras) {
        Write-Host "Found $($cameras.Count) camera device(s):" -ForegroundColor Yellow
        Write-Host ""
        
        $index = 1
        foreach ($camera in $cameras) {
Write-Host "Camera ${index}:" -ForegroundColor Cyan
            Write-Host "  Name: $($camera.FriendlyName)"
            Write-Host "  Status: $($camera.Status)"
            Write-Host "  Instance ID: $($camera.InstanceId)"
            Write-Host "  Device ID: $($camera.DeviceID)"
            Write-Host ""
            $index++
        }
        
        # Highlight potential front cameras
        $frontCameras = $cameras | Where-Object {
            $_.FriendlyName -match "Front|Integrated" -and
            $_.FriendlyName -notmatch "Hello|IR|Infrared"
        }
        
        if ($frontCameras) {
            Write-Host "=== Potential Front Camera(s) ===" -ForegroundColor Green
            foreach ($camera in $frontCameras) {
                Write-Host "  - $($camera.FriendlyName) (Status: $($camera.Status))" -ForegroundColor Yellow
            }
        } else {
            Write-Host "No obvious front camera found. You may need to modify the script filter." -ForegroundColor Red
        }
        
        # Show Windows Hello cameras
        $helloCameras = $cameras | Where-Object {
            $_.FriendlyName -match "Hello|IR|Infrared"
        }
        
        if ($helloCameras) {
            Write-Host ""
            Write-Host "=== Windows Hello Camera(s) ===" -ForegroundColor Green
            foreach ($camera in $helloCameras) {
                Write-Host "  - $($camera.FriendlyName) (Status: $($camera.Status))" -ForegroundColor Cyan
            }
        }
    } else {
        Write-Host "No camera devices found!" -ForegroundColor Red
    }
} catch {
    Write-Host "Error retrieving camera devices: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
