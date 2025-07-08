:: StartCameraControl.bat
@echo off
REM Windows Hello Face ID Camera Control Service Launcher
REM Requires Administrator privileges

net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run as Administrator.
    exit /b 1
)

echo Starting Windows Hello Face ID camera monitoring service...
start "" powershell.exe -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0WindowsHelloCameraControl.ps1"
echo Service started. Check the log at %TEMP%\WindowsHelloCameraControl.log for details.
exit /b 0
