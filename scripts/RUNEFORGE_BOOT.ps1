$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "RUNEFORGE - SYSTEM BOOT"

# --- CONFIGURACIÓN DE RUTAS ---
$CoreDir = "C:\RUNEFORGE_V2_CORE"
$BackendDir = "$CoreDir\whisper-backend"
$ScriptsDir = "$CoreDir\scripts"
$DashboardDir = "$CoreDir\nexus-dashboard"
$ReleaseDir = "$CoreDir\target\release"
$VenvPython = "$BackendDir\venv\Scripts\python.exe"

function Write-Step ($msg) {
    Write-Host "`n[*] $msg" -ForegroundColor Cyan
}

function Write-Success ($msg) {
    Write-Host "    [OK] $msg" -ForegroundColor Green
}

function Write-Error ($msg) {
    Write-Host "    [X] $msg" -ForegroundColor Red
}

Clear-Host
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "       RUNEFORGE V2 - INICIANDO ECOSISTEMA     " -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta

# 1. LIMPIEZA DE PROCESOS ZOMBIS
Write-Step "Limpiando procesos anteriores..."
Get-Process python, node, dictate-studio-v2 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Write-Success "Procesos anteriores terminados."

# 2. INICIAR BACKEND DE WHISPER (GPU)
Write-Step "Iniciando Backend de Whisper (GPU CUDA)..."
if (Test-Path $VenvPython) {
    $backendProc = Start-Process -FilePath $VenvPython -ArgumentList "server.py" -WorkingDirectory $BackendDir -WindowStyle Minimized -PassThru
    Write-Success "Backend iniciado en segundo plano (PID: $($backendProc.Id))."
    
    # Esperar a que el backend cargue el modelo en la GPU
    Write-Host "    [*] Esperando a que la GPU cargue el modelo (esto toma ~6 segundos)..." -ForegroundColor Yellow
    $ready = $false
    for ($i = 1; $i -le 15; $i++) {
        Start-Sleep -Seconds 1
        try {
            $res = Invoke-RestMethod -Uri "http://127.0.0.1:8081/health" -TimeoutSec 1 -ErrorAction Stop
            if ($res.status -eq "ok") { $ready = $true; break }
        } catch {}
    }
    
    if ($ready) { Write-Success "Backend listo y escuchando en el puerto 8081." }
    else { Write-Error "El backend no respondió a tiempo. Revisa la ventana minimizada de Python." }
} else {
    Write-Error "No se encontró el entorno virtual de Python en $VenvPython"
}

# 3. INICIAR EL CEREBRO (MONITOR)
Write-Step "Iniciando Nexus Brain (Monitor del Ecosistema)..."
$brainScript = "$ScriptsDir\brain_hub.py"
if (Test-Path $brainScript) {
    # Lo iniciamos en una ventana nueva para que veas los latidos
    Start-Process -FilePath "python" -ArgumentList "`"$brainScript`"" -WorkingDirectory $ScriptsDir -WindowStyle Minimized
    Write-Success "Cerebro iniciado (generando ecosystem.json)."
} else {
    Write-Error "No se encontró brain_hub.py"
}

# 4. INICIAR DASHBOARD (VITE / SVELTE)
Write-Step "Iniciando Servidor del Mapa Estelar (Vite)..."
if (Test-Path $DashboardDir) {
    # Iniciar Vite en una ventana nueva
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm run dev" -WorkingDirectory $DashboardDir -WindowStyle Minimized
    Write-Success "Servidor Frontend iniciado."
    
    # Esperar un par de segundos y abrir el navegador
    Start-Sleep -Seconds 3
    Write-Step "Abriendo el Mapa Estelar en el navegador..."
    Start-Process "http://localhost:5173"
} else {
    Write-Error "No se encontró la carpeta nexus-dashboard"
}

# 5. ABRIR DICTATE STUDIO (TAURI)
Write-Step "Abriendo DICTATE Studio (App de Dictado)..."
$AppExe = "$ReleaseDir\dictate-studio-v2.exe"
if (Test-Path $AppExe) {
    Start-Process -FilePath $AppExe -WorkingDirectory $ReleaseDir
    Write-Success "Aplicación de dictado abierta."
} else {
    Write-Error "No se encontró dictate-studio-v2.exe"
}

Write-Host "`n===============================================" -ForegroundColor Magenta
Write-Host "      ECOSISTEMA EN LÍNEA Y OPERATIVO          " -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host " - Whisper IA: Corriendo (Minimizado)" -ForegroundColor Gray
Write-Host " - Nexus Brain: Corriendo (Minimizado)" -ForegroundColor Gray
Write-Host " - Dashboard: Abierto en el navegador" -ForegroundColor Gray
Write-Host " - DICTATE Studio: Abierto" -ForegroundColor Gray
Write-Host "`nDeja esta ventana abierta si deseas cerrar todo de golpe presionando Ctrl+C." -ForegroundColor Yellow

# Mantener el script vivo para poder hacer un cierre limpio (Kill on exit)
try {
    while ($true) { Start-Sleep -Seconds 5 }
} finally {
    Write-Host "`n[!] Cerrando ecosistema..." -ForegroundColor Red
    Get-Process python, node, dictate-studio-v2 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Todos los procesos han sido detenidos." -ForegroundColor Green
}