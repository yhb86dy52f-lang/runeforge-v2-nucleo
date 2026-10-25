$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$PythonExe = "$BackendDir\venv\Scripts\python.exe"
$ServerScript = "$BackendDir\server.py"
$LogFile = "$BackendDir\startup_error.log"

Log "=== DIAGNÓSTICO Y ARRANQUE DE EMERGENCIA ==="

# 1. Verificar archivos
if (-not (Test-Path $PythonExe)) { Log "[X] FALTA PYTHON: $PythonExe"; $Report.ToString() | Set-Clipboard; return }
if (-not (Test-Path $ServerScript)) { Log "[X] FALTA SERVER.PY: $ServerScript"; $Report.ToString() | Set-Clipboard; return }

# 2. Matar cualquier proceso Python zombie
Log "[1] Matando procesos Python previos..."
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 3. Verificar si el puerto 8081 está siendo usado por otra cosa
$portCheck = Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue
if ($portCheck) {
    Log "[!] El puerto 8081 está OCUPADO por el PID: $($portCheck.OwningProcess). Matando..."
    Stop-Process -Id $portCheck.OwningProcess -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# 4. Arrancar backend capturando salida en un log (para ver si crashea)
Log "[2] Iniciando backend (tiempo máximo de espera: 45 segundos)..."
if (Test-Path $LogFile) { Remove-Item $LogFile -Force }

$proc = Start-Process -FilePath $PythonExe -ArgumentList "server.py" -WorkingDirectory $BackendDir -RedirectStandardOutput "$BackendDir\out.log" -RedirectStandardError $LogFile -PassThru -WindowStyle Hidden

$maxWait = 45
$isRunning = $false
for ($i = 1; $i -le $maxWait; $i++) {
    Start-Sleep -Seconds 1
    if ($proc.HasExited) {
        Log "[X] El proceso de Python CRASHEÓ inmediatamente (Exit Code: $($proc.ExitCode))."
        break
    }
    try {
        $res = Invoke-RestMethod -Uri "http://127.0.0.1:8081/health" -TimeoutSec 1 -ErrorAction Stop
        if ($res.status -eq "ok") {
            Log "[OK] Backend ARRIBA y respondiendo tras $i segundos."
            $isRunning = $true
            break
        }
    } catch {
        # Sigue esperando
        if ($i % 5 -eq 0) { Log "  ... esperando ($i s) ..." }
    }
}

# 5. Si falló, mostrar el log de error
if (-not $isRunning) {
    Log "`n=== ERROR CAPTURADO DEL BACKEND ==="
    if (Test-Path $LogFile) {
        Get-Content $LogFile | Select-Object -Last 15 | ForEach-Object { Log "  $_" }
    } else {
        Log "No se generó archivo de log. Posible bloqueo de DLL o falta de memoria."
    }
} else {
    Log "`n[ÉXITO] Ve a DICTATE Studio, apaga el micrófono y vuélvelo a encender."
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
