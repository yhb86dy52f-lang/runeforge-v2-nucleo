$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

Log "=== ARRANCANDO MOSQUITTO FORZADO ==="

# 1. Matar cualquier proceso previo
Get-Process mosquitto -EA SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

# 2. Reescribir config por si está corrupta
$Conf = @"
listener 1883
allow_anonymous true

listener 9001
protocol websockets
allow_anonymous true

persistence false
log_dest stdout
"@
$ConfPath = "C:\Program Files\mosquitto\mosquitto.conf"
if (Test-Path (Split-Path $ConfPath -Parent)) {
    [IO.File]::WriteAllText($ConfPath, $Conf)
    Log "[OK] mosquitto.conf reescrito."
} else {
    Log "[X] No se encontró C:\Program Files\mosquitto"
}

# 3. Intentar arrancar como servicio de Windows
try {
    Start-Service mosquitto -ErrorAction Stop
    Log "[OK] Servicio de Windows iniciado."
} catch {
    Log "[!] Servicio de Windows falló. Lanzando en segundo plano..."
    # Arrancar directo y oculto
    Start-Process -FilePath "C:\Program Files\mosquitto\mosquitto.exe" -ArgumentList "-c `"$ConfPath`"" -WindowStyle Hidden
    Start-Sleep -Seconds 2
}

# 4. Verificar que el puerto 1883 esté escuchando
$PortOpen = (Get-NetTCPConnection -LocalPort 1883 -State Listen -EA SilentlyContinue) -ne $null
if ($PortOpen) {
    Log "[OK] Puerto 1883 ACTIVO. El ESP32 (COM5) debería conectar en 5 segundos."
} else {
    Log "[X] Puerto 1883 CERRADO. Revisa si hay bloqueo de Firewall o Antivirus."
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles. Ctrl+V para pegar." -ForegroundColor Green
