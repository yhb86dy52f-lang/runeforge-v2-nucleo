$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Report = [System.Collections.Generic.List[string]]::new()
$Report.Add('=== REPORTE DE AUDITORIA FORENSE RUNEFORGE ===')
$Report.Add('Fecha: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$Report.Add('')

$Report.Add('[1] ARCHIVOS CRITICOS:')
$files = @('C:\RUNEFORGE_V2_CORE\scripts\RUNEFORGE_BOOT.ps1', 'C:\RUNEFORGE_V2_CORE\scripts\brain_hub.py', 'C:\RUNEFORGE_V2_CORE\nexus-tactical')
foreach ($f in $files) { 
    if (Test-Path $f) { $Report.Add('  [OK] ' + $f) } else { $Report.Add('  [X] FALTA: ' + $f) } 
}

$Report.Add(''); $Report.Add('[2] ESTADO DE SERVICIOS:')
# Puertos: Whisper 8081, Fastify 3100, Ollama 11434
$ports = @{8081='Whisper IA'; 3100='Fastify'; 11434='Ollama'}
foreach ($p in $ports.Keys) { 
    $conn = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
    if ($conn) { $Report.Add('  [ONLINE] ' + $ports[$p]) } else { $Report.Add('  [OFFLINE] ' + $ports[$p]) } 
}

# Detección de Tauri (Busca app.exe en target\debug)
$tauriProc = Get-Process -Name "app" -ErrorAction SilentlyContinue | Where-Object { $_.Path -match 'target\\debug\\app.exe' }
if ($tauriProc) { $Report.Add('  [ONLINE] Tauri Core (app.exe en ejecución)') } 
else { 
    # Fallback por si el path falla
    $tauriAlt = Get-Process -Name "app" -ErrorAction SilentlyContinue
    if ($tauriAlt) { $Report.Add('  [ONLINE] Tauri Core (app.exe detectado)') }
    else { $Report.Add('  [OFFLINE] Tauri Core') }
}

# Detección de Tailscale
$ts = Get-Service Tailscale -ErrorAction SilentlyContinue
if ($ts -and $ts.Status -eq 'Running') { $Report.Add('  [ONLINE] Tailscale Mesh') } else { $Report.Add('  [OFFLINE] Tailscale Mesh') }

$Report.Add(''); $Report.Add('[3] PROCESOS ACTIVOS (Forense):')
$procs = Get-CimInstance Win32_Process | Where-Object { 
    ($_.Name -match '^(python|node|cargo|app|tauri)\.exe$') -and 
    ($_.CommandLine -match 'RUNEFORGE|whisper-backend|brain_hub|nexus-tactical|vite|tauri|pm2') 
}
if ($procs) { 
    foreach ($proc in $procs) { 
        $mem = [math]::Round($proc.WorkingSetSize / 1MB, 2)
        $Report.Add('  [ACTIVO] ' + $proc.Name + ' (PID: ' + $proc.ProcessId + ', RAM: ' + $mem + ' MB)')
    } 
} else { $Report.Add('  [LIMPIO] Ningun proceso del ecosistema activo.') }

$Report.Add(''); $Report.Add('[4] HARDWARE:')
$cpu = (Get-CimInstance Win32_Processor).LoadPercentage
$os = Get-CimInstance Win32_OperatingSystem
$ram = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)
$Report.Add('  [CPU] ' + $cpu + '% | [RAM] ' + $ram + ' GB')
$Report.Add(''); $Report.Add('=========================================')

$FinalOutput = $Report -join "`r`n"
$FinalOutput | Set-Clipboard
Write-Host $FinalOutput -ForegroundColor Gray
Write-Host "[OK] Reporte copiado al portapapeles." -ForegroundColor Cyan