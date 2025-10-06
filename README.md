# An improved fork of windows-hello-patch

## Why?

The script forces Windows Hello to use only IR camera for facial recognition. This fixes the annoying change with Windows Hello after the 24H2 update, that is, require both the ir and the regular webcam for indentifying face, which make it more secure with trade-off of being significantly slower and no longer working in the dark.

## How it works:

The script works the same way the original windows-hello-patch did, but is heavily stripped down (removed all the logging functionalities and error handling). It also uses a better way to identify regular webcam (using Device Capabilities property instead of searching for matched keyword in the device's name) and use "pnputil" to list/enable/disable webcam instead of the cmdlet alternative (faster I guess?)

So in general, what the script does is:

1. Find regular webcam (the webcam that does not have SECUREDEVICE flag in DEVPKEY_Device_Capabilities) using pnputil and store its Instance ID
2. Constantly check whether LogonUI (lock screen) or CredentialUIBroker (authentication window) process is present, with 500ms delay in between
3. Disable the regular webcam whenever the above conditions is met, then re-enable when no longer met

## How to use:

Run the "whcc.ps1" script with administrator privilege and ExecutionPolicy bypassed:

`powershell -ExecutionPolicy Bypass -File .\whcc.ps1`

## Create startup task in Task Scheduler

We'll want to make the script run right when the computer startup, just run the "install_task.bat" file, double click on the file or:

`install_task.bat`

This will run the "cre_task.ps1" script, which will then create a scheduled task that run on device bootup. You'll be prompted to run the script as administrator if not already so.
