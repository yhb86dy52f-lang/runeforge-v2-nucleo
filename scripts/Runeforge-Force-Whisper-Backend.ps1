$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$PythonExe = "$BackendDir\venv\Scripts\python.exe"
$HealthUrl = "http://127.0.0.1:8081/health"

Log "=== VERIFICANDO BACKEND WHISPER ==="
$isRunning = $false

try {
    $res = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 2 -ErrorAction Stop
    if ($res.status -eq "ok") {
        Log "[OK] Backend ya está activo (Modelo: $($res.model), GPU: $($res.device))"
        $isRunning = $true
    }
} catch {
    Log "[!] Backend apagado o no responde. Iniciando..."
}

if (-not $isRunning) {
    if (Test-Path $PythonExe) {
        # Matar procesos python colgados de Whisper
        Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $PythonExe } | Stop-Process -Force
        Start-Sleep -Seconds 1
        
        # Arrancar backend en segundo plano (oculto)
        Start-Process -FilePath $PythonExe -ArgumentList "server.py" -WorkingDirectory $BackendDir -WindowStyle Hidden
        Log "[>] Lanzando backend. Esperando a que cargue el modelo en la GTX 1660 SUPER..."
        
        $retries = 20
        while ($retries -gt 0) {
            Start-Sleep -Seconds 1
            try {
                $res = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 1 -ErrorAction Stop
                if ($res.status -eq "ok") {
                    Log "[OK] Backend listo y escuchando en el puerto 8081."
                    $isRunning = $true
                    break
                }
            } catch {}
            $retries--
        }
        
        if (-not $isRunning) {
            Log "[X] Timeout. El backend no arrancó en 20 segundos."
        }
    } else {
        Log "[X] No se encontró el Python del entorno virtual en: $PythonExe"
    }
}

Log "`n=== INSTRUCCIONES ==="
Log "Si la app sigue mostrando 'Error: network', haz clic en el micrófono para detenerlo y vuelve a hacer clic para iniciar la grabación. El error debería desaparecer."

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
