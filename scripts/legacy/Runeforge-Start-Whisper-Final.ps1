$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$PythonExe = "$BackendDir\venv\Scripts\python.exe"
$HealthUrl = "http://127.0.0.1:8081/health"

Log "=== ARRANCANDO BACKEND WHISPER (FINAL) ==="

# 1. Matar procesos previos
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Lanzar el servidor de forma oculta
Log "[1] Iniciando servidor Python..."
Start-Process -FilePath $PythonExe -ArgumentList "server.py" -WorkingDirectory $BackendDir -WindowStyle Hidden

# 3. Bucle de espera a que la GPU cargue el modelo
Log "[2] Esperando a que el modelo large-v3-turbo se cargue en la GPU (esto puede tomar 10-15 segundos)..."
$isReady = $false
for ($i = 1; $i -le 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        $res = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 1 -ErrorAction Stop
        if ($res.status -eq "ok") {
            Log "`n[OK] Backend arriba y respondiendo."
            Log "     Modelo: $($res.model)"
            Log "     Dispositivo: $($res.device)"
            $isReady = $true
            break
        }
    } catch {
        if ($i % 5 -eq 0) { Write-Host "     ... esperando ($i s) ..." }
    }
}

if (-not $isReady) {
    Log "`n[X] El backend no respondió en 30 segundos. Revisa si hay un error en la consola."
} else {
    Log "`n[ÉXITO] Ve a la ventana de DICTATE Studio. Apaga el micrófono (o presiona Ctrl+Space) y vuélvelo a encender."
    Log "         El error 'Error: network' debería desaparecer inmediatamente."
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
