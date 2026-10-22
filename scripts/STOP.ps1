# Verificar si somos Administrador, si no, elevarse
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[!] Solicitando permisos de Administrador..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Clear-Host
Write-Host "=========================================================" -ForegroundColor Red
Write-Host "        [STOP] RUNEFORGE: PARADA DE EMERGENCIA           " -ForegroundColor Red
Write-Host "=========================================================" -ForegroundColor Red
Write-Host ""

Write-Host "[*] Terminando procesos raiz..." -ForegroundColor Yellow
taskkill /F /IM python.exe /T 2>&1 | Out-Null
taskkill /F /IM cargo.exe /T 2>&1 | Out-Null
taskkill /F /IM app.exe /T 2>&1 | Out-Null

Write-Host "[*] Ejecutando apagado de PM2..." -ForegroundColor Yellow
& pm2 kill 2>&1 | Out-Null

Write-Host "[*] Buscando y eliminando procesos PM2 remanentes..." -ForegroundColor Yellow
# Buscar cualquier proceso node que tenga Daemon.js o pm2 en su comando
$nodeProcs = Get-CimInstance Win32_Process -Filter "Name = 'node.exe'"
foreach ($np in $nodeProcs) {
    if ($np.CommandLine -like "*pm2*" -or $np.CommandLine -like "*Daemon.js*" -or $np.CommandLine -like "*nexus-tactical*" -or $np.CommandLine -like "*vite*") {
        Write-Host "    Matando PID: $($np.ProcessId) ($($np.CommandLine))" -ForegroundColor DarkGray
        taskkill /F /PID $np.ProcessId /T 2>&1 | Out-Null
    }
}

Write-Host "[*] Liberando puertos..." -ForegroundColor Yellow
$ports = @(8081, 8080, 5173, 3001, 11434)
foreach ($port in $ports) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($conn) { $conn | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue } }
}

Write-Host "[*] Esperando 2 segundos para asegurar la muerte de procesos..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

Write-Host "`n[*] Verificando estado final (Auditoria automatica)..." -ForegroundColor Yellow
& "C:\RUNEFORGE_V2_CORE\scripts\AUDIT.ps1"

Write-Host "`n=========================================================" -ForegroundColor Red
Write-Host "  [OK] SISTEMA PROTEGIDO. PC EN MODO DE REPOSO." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Red
Read-Host "Presiona ENTER para cerrar..."