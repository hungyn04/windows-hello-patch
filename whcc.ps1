$frontCamera = (ConvertFrom-CSV (pnputil /enum-devices /class Camera /properties /format csv) | Where-Object { ($_.Key -eq "DEVPKEY_Device_Capabilities") -and (([uint32]$_.Value - 1024) -lt 0) }).InstanceId
$wasHelloActive = $false
while ($true) {
    $isHelloActive = $null -ne (Get-Process "CredentialUIBroker", "LogonUI" -ErrorAction SilentlyContinue)
    if ($isHelloActive -and -not $wasHelloActive) {
        pnputil /disable-device $frontCamera
        $wasHelloActive = $true
    }
    elseif (-not $isHelloActive -and $wasHelloActive) {
        pnputil /enable-device $frontCamera
        $wasHelloActive = $false
    }
    Start-Sleep -Milliseconds 500
}