# windows-hello-patch

## How to Use:

Step 1: Identify Your Front Camera
First, run the camera identification script to see all your camera devices:
pwsh
Step 2: Run the Service
To start the camera control service:
1. Right-click on StartCameraControl.bat and select "Run as administrator"
2. Or run PowerShell as administrator and execute: .\WindowsHelloCameraControl.ps1

## How It Works:

The script continuously monitors for:
- Windows Hello authentication processes (WinBio, AuthHost, LogonUI)
- Lock screen activity
- Biometric service activity

When Windows Hello Face ID is detected:
1. Disables your front camera device
2. Re-enables it after the authentication process ends

## Features:

- Targets front camera specifically - Filters for cameras with "Front" or "Integrated" in the name
- Avoids IR cameras - Excludes Windows Hello IR cameras from being controlled
- Logging - Creates a log file at %TEMP%\WindowsHelloCameraControl.log
- Administrator check - Ensures the script runs with required privileges
- Background operation - Runs continuously in the background
- Error handling - Gracefully handles errors and continues monitoring
