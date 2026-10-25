# ============================================
# RUNEFORGE - UART CONSOLE BRIDGE (TV CVTE)
# ============================================
$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$m)
    Write-Host $m
    [void]$capture.Add($m)
}

Log "==============================================="
Log " RUNEFORGE - UART CONSOLE BRIDGE (TV CVTE)"
Log "==============================================="
Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log ""

# 1. Detectar Puertos USB-Serial
Log "[*] Buscando adaptadores USB-to-TTL (CH340, CP210x, FTDI)..."
$ports = Get-CimInstance Win32_SerialPort | Where-Object { $_.Name -match "CH340|CP210|FTDI|Prolific|USB" }

if (-not $ports) {
    Log "[-] No se detectaron adaptadores USB-Serial."
    Log "[!] ACCION: Conecta el USB-to-TTL a la PC."
    $capture | Set-Clipboard
    return
}

foreach ($p in $ports) {
    Log "[+] Encontrado: $($p.Name) en el puerto $($p.DeviceID)"
}

$selectedPort = $ports[0].DeviceID
Log "[*] Abriendo $selectedPort a 115200 baudios, 8N1..."
Log "[!] IMPORTANTE: Conecta TX del USB al RX de la TV (Cable BLU) y RX del USB al TX de la TV (Cable GRN). GND a GND (Cable BLK)."
Log "-------------------------------------------------"

# 2. Configurar el Puerto Serial
$serial = New-Object System.IO.Ports.SerialPort($selectedPort, 115200, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One)
$serial.ReadTimeout = 500
$serial.NewLine = "`n"

try {
    $serial.Open()
    Log "[+] Puerto abierto. Capturando consola..."
    Log "[!] Si la TV estaba apagada, enciéndela ahora para capturar el Boot Log."
    Log "[!] Presiona CTRL+C para detener la captura."
    Log "-------------------------------------------------"
    
    $logPath = "C:\RUNEFORGE_V2_CORE\logs\uart_tv.log"
    New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null
    
    while ($true) {
        if ($serial.BytesToRead -gt 0) {
            $data = $serial.ReadExisting()
            Write-Host $data -NoNewline
            Add-Content -Path $logPath -Value $data -NoNewline
            [void]$capture.Add($data)
        }
        Start-Sleep -Milliseconds 50
    }
} catch {
    Log "[-] Error en puerto serial: $_"
} finally {
    if ($serial.IsOpen) { $serial.Close() }
    Log ""
    Log "-------------------------------------------------"
    Log "[OK] Captura finalizada. Log guardado en: $logPath"
    $capture | Set-Clipboard
    Log "[OK] Reporte copiado al portapapeles (Ctrl+V)."
}