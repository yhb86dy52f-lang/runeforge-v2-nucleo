$LogDir = "C:\RUNEFORGE_V2_CORE\logs"
$TransFile = "$LogDir\last_boot_transcript.txt"
$null = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue

Clear-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "       RUNEFORGE V2 - INICIANDO ECOSISTEMA               " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# REGLA CANÓNICA: Iniciar captura de consola
Start-Transcript -Path $TransFile -Force | Out-Null

$targets = Get-CimInstance Win32_Process | Where-Object { 
    ($_.Name -match '^(python|node|cargo|app|tauri)\.exe$') -and 
    ($_.CommandLine -match 'RUNEFORGE|whisper-backend|brain_hub|nexus-tactical|vite|tauri') 
}
foreach ($t in $targets) { Stop-Process -Id $t.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500

Write-Host "[*] Arrancando Servicios..." -ForegroundColor Yellow
$tailscaleSvc = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
if ($tailscaleSvc -and $tailscaleSvc.Status -ne 'Running') { Start-Service -Name "Tailscale" -ErrorAction SilentlyContinue }

if (-not (Get-Process -Name "ollama" -ErrorAction SilentlyContinue)) { Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden }
if (Get-Command pm2 -ErrorAction SilentlyContinue) { Start-Process -FilePath "cmd.exe" -ArgumentList "/c pm2 start 1 > `"$LogDir\pm2_start.log`" 2>&1" -WindowStyle Hidden }

$whisperPath = "C:\RUNEFORGE_V2_CORE\whisper-backend\venv\Scripts\python.exe"
if (Test-Path $whisperPath) { Start-Process -FilePath $whisperPath -ArgumentList "server.py" -WorkingDirectory "C:\RUNEFORGE_V2_CORE\whisper-backend" -WindowStyle Hidden -RedirectStandardOutput "$LogDir\whisper_out.log" -RedirectStandardError "$LogDir\whisper_err.log" }

$brainPath = "C:\RUNEFORGE_V2_CORE\scripts\brain_hub.py"
if (Test-Path $brainPath) { Start-Process -FilePath "python" -ArgumentList "-X utf8 `"$brainPath`"" -WorkingDirectory "C:\RUNEFORGE_V2_CORE\scripts" -WindowStyle Hidden -RedirectStandardOutput "$LogDir\brain_out.log" -RedirectStandardError "$LogDir\brain_err.log" }

$tauriPath = "C:\RUNEFORGE_V2_CORE\nexus-tactical"
if (Test-Path $tauriPath) { Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm run tauri dev > `"$LogDir\tauri_out.log`" 2>&1" -WorkingDirectory $tauriPath -WindowStyle Hidden }

Write-Host "`n[*] Esperando 12 segundos a que los servicios inicialicen..." -ForegroundColor Yellow
Start-Sleep -Seconds 12

Write-Host "[*] Verificando estado..." -ForegroundColor Yellow
& "$PSScriptRoot\AUDIT.ps1"

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "  [OK] ARRANQUE GLOBAL FINALIZADO." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Cyan
Read-Host "Presiona ENTER para cerrar..."

# REGLA CANÓNICA: Detener captura y copiar TODO al portapapeles
Stop-Transcript | Out-Null
Get-Content $TransFile -Raw | Set-Clipboard
Write-Host "[OK] Log completo del arranque copiado al portapapeles." -ForegroundColor Cyan