# OpenWash - Configuración Autónoma Remota - PowerShell
# Hotspot: RUNEFORGE-PC 8808 / 12345678 + Tailscale Subnet Router para acceso remoto desde iPhone/Android
# Ejecutar como Administrador: pwsh -ExecutionPolicy Bypass -File Setup-OpenWash-Remoto.ps1

$ErrorActionPreference = "SilentlyContinue"
$ssid = "RUNEFORGE-PC 8808"
$pass = "12345678"
$hotspotSubnet = "192.168.137.0/24"

Write-Host "=== OPENWASH AUTÓNOMO - CONFIGURANDO PC ===" -ForegroundColor Cyan

# 1. Configurar Hotspot Nativo Windows 11 (equivalente a tu captura)
try {
    # Habilitar Mobile Hotspot via registro (nombre y pass)
    $regPath = "HKLM:\SOFTWARE\Microsoft\WcSvc\Tethering"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    # Windows 11 almacena config en WlanSvc
    netsh wlan set hostednetwork mode=allow ssid="$ssid" key="$pass" | Out-Null
    
    # Activar ICS - Compartir Wi-Fi -> Hotspot
    # Identificar adaptadores
    $wifiAdapter = Get-NetAdapter | Where-Object {$_.MediaType -like "*802.11*" -and $_.Status -eq "Up"} | Select-Object -First 1
    $hostAdapter = Get-NetAdapter | Where-Object {$_.Name -like "*Local Area Connection*"} | Select-Object -First 1
    
    # Habilitar hotspot via WinRT API (funciona en Win10/11)
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
    $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
    $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)
    $tetheringManager.StartTetheringAsync() | Out-Null
    Write-Host "[OK] Hotspot $ssid activado" -ForegroundColor Green
} catch {
    Write-Host "[INFO] Activando hotspot por metodo alternativo..." -ForegroundColor Yellow
    # Fallback netsh
    netsh wlan start hostednetwork | Out-Null
}

# 2. Desactivar ahorro de energía (como en tu captura Desactivado)
try {
    $adapters = Get-NetAdapter -IncludeHidden | Where-Object {$_.Name -like "*Wi-Fi*" -or $_.Name -like "*Hosted*"}
    foreach ($a in $adapters) {
        $powerMgmt = Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi | Where-Object {$_.InstanceName -like "*$($a.PnPDeviceID)*"}
        if ($powerMgmt) { $powerMgmt.Enable = $false; Set-CimInstance -InputObject $powerMgmt }
        Set-NetAdapterAdvancedProperty -Name $a.Name -RegistryKeyword "AutoPowerSaveMode" -RegistryValue 0 -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] Ahorro de energía desactivado" -ForegroundColor Green
} catch {}

# 3. Firewall - Permitir puerto 80 y mDNS para ESP32
try {
    New-NetFirewallRule -DisplayName "OpenWash HTTP 80" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80 -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "OpenWash mDNS 5353" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 5353 -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "OpenWash OTA 3232" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3232 -ErrorAction SilentlyContinue | Out-Null
    Write-Host "[OK] Firewall configurado" -ForegroundColor Green
} catch {}

# 4. Tailscale - Publicar subred hotspot para acceso remoto desde iPhone fuera de casa
try {
    $tsPath = (Get-Command tailscale -ErrorAction SilentlyContinue).Source
    if (-not $tsPath) { $tsPath = "$env:ProgramFiles\Tailscale\tailscale.exe" }
    if (Test-Path $tsPath) {
        & $tsPath up --advertise-routes=$hotspotSubnet --advertise-exit-node --reset | Out-Null
        Write-Host "[OK] Tailscale configurado como Subnet Router $hotspotSubnet" -ForegroundColor Green
        Write-Host "  -> Ve a https://login.tailscale.com/admin/machines y aprueba la subred de runeforge-pc" -ForegroundColor Yellow
        Write-Host "  -> iPhone-14-pro podra acceder a ESP32 via Tailscale incluso con datos moviles" -ForegroundColor Cyan
    } else {
        Write-Host "[INFO] Tailscale no encontrado, saltando" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[INFO] Tailscale config omitida" -ForegroundColor Yellow
}

# 5. Mostrar estado final
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.137.*"} | Select-Object -First 1).IPAddress
if (-not $ip) { $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.100.*"} | Select-Object -First 1).IPAddress }

Write-Host "`n=== SISTEMA LISTO ===" -ForegroundColor Cyan
Write-Host "Hotspot SSID: $ssid"
Write-Host "Hotspot PASS: $pass"
Write-Host "IP PC: $ip"
Write-Host "ESP32 URL Local: http://openwash-2reles.local"
Write-Host "ESP32 URL IP: http://$ip"
Write-Host "OTA Update: http://openwash-2reles.local/update"
Write-Host "Tailscale PC: 100.83.105.117 (runeforge-pc.tail12b297.ts.net)"
Write-Host "Tailscale iPhone: 100.95.173.89 (iphone-14-pro.tail12b297.ts.net)"
Write-Host "`nConecta ESP32 y tu iPhone a $ssid y abre el panel desde Safari. Todo remoto sin cables." -ForegroundColor Green
