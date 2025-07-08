@echo off
REM Windows Hello Face ID Camera Control Service Launcher
REM This batch file runs the PowerShell script as a background service

echo Starting Windows Hello Face ID Camera Control Service...

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires Administrator privileges.
    echo Please run as Administrator.
    pause
    exit /b 1
)

REM Start the PowerShell script in the background
echo Starting camera monitoring service...
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0WindowsHelloCameraControl.ps1"

echo Service started. Check the log file at %TEMP%\WindowsHelloCameraControl.log for details.
pause
