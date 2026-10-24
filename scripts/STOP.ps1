# ==============================================================================
# RUNEFORGE V2.6.2 - PARADA DE EMERGENCIA (APAGÓN TOTAL)
# ==============================================================================
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$LogDir = "C:\RUNEFORGE_V2_CORE\logs"
$TransFile = "$LogDir\last_stop_transcript.txt"
$null = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue

Clear-Host
Write-Host "=========================================================" -ForegroundColor Red
Write-Host "        [STOP] RUNEFORGE: PARADA DE EMERGENCIA           " -ForegroundColor Red
Write-Host "=========================================================" -ForegroundColor Red

# REGLA CANÓNICA: Iniciar captura de consola
Start-Transcript -Path $TransFile -Force | Out-Null

Write-Host "[*] 1. Deteniendo PM2 (silencioso)..." -ForegroundColor Yellow
# Usamos cmd.exe para que PowerShell 5.1 no convierta el stderr en un error rojo
cmd.exe /c "pm2 kill >nul 2>&1"

Write-Host "[*] 2. Deteniendo Ollama..." -ForegroundColor Yellow
Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue

Write-Host "[*] 3. Deteniendo Tailscale Mesh (Cortando red)..." -ForegroundColor Yellow
Stop-Service -Name "Tailscale" -Force -ErrorAction SilentlyContinue

Write-Host "[*] 4. Cazando procesos RUNEFORGE (Node, Python, Cargo, App)..." -ForegroundColor Yellow
$targets = Get-CimInstance Win32_Process | Where-Object { 
    ($_.Name -match '^(python|node|cargo|app|tauri)\.exe$') -and 
    ($_.CommandLine -match 'RUNEFORGE|whisper-backend|brain_hub|nexus-tactical|vite|tauri|pm2') 
}
foreach ($t in $targets) { 
    Write-Host "    -> Matando PID: $($t.ProcessId) ($($t.Name))" -ForegroundColor DarkGray
    taskkill /F /PID $t.ProcessId /T 2>&1 | Out-Null 
}

Write-Host "[*] 5. Liberando puertos huérfanos (8080, 8081, 3100, 11434, 1420)..." -ForegroundColor Yellow
$ports = @(8080, 8081, 3100, 11434, 1420)
foreach ($port in $ports) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conn) { 
        $conn | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { 
            Write-Host "    -> Matando proceso en puerto $port (PID: $_)" -ForegroundColor DarkGray
            Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue 
        } 
    }
}

Write-Host "`n[*] 6. Verificando estado final (Apagón Total)..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
& "$PSScriptRoot\AUDIT.ps1"

Write-Host "`n=========================================================" -ForegroundColor Red
Write-Host "  [OK] SISTEMA TOTALMENTE APAGADO. PC EN MODO DE REPOSO." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Red

Read-Host "Presiona ENTER para cerrar..."

# REGLA CANÓNICA: Detener captura y copiar al portapapeles
Stop-Transcript | Out-Null
Get-Content $TransFile -Raw | Set-Clipboard
Write-Host "`n[OK] Log completo de la parada copiado al portapapeles (Ctrl+V)." -ForegroundColor Cyan