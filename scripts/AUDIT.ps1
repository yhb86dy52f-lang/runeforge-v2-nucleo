[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Report = @()
$Report += '=== REPORTE DE AUDITORIA FORENSE RUNEFORGE ==='
$Report += ('Fecha: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$Report += ''

$Report += '[1] ARCHIVOS CRITICOS:'
$files = @('C:\RUNEFORGE_V2_CORE\scripts\RUNEFORGE_BOOT.ps1', 'C:\RUNEFORGE_V2_CORE\scripts\brain_hub.py', 'C:\RUNEFORGE_V2_CORE\nexus-tactical')
foreach ($f in $files) { 
    if (Test-Path $f) { $Report += ('  [OK] ' + $f) } else { $Report += ('  [X] FALTA: ' + $f) } 
}

$Report += ''; $Report += '[2] ESTADO DE PUERTOS:'
$ports = @{8081='Whisper IA'; 8080='Vite/Tauri Dev'; 5173='Vite Alterno'; 3001='Fastify'; 11434='Ollama'}
foreach ($p in $ports.Keys) { 
    $conn = Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue
    if ($conn) { $Report += ('  [ONLINE] ' + $ports[$p]) } else { $Report += ('  [OFFLINE] ' + $ports[$p]) } 
}

$Report += ''; $Report += '[3] PROCESOS ACTIVOS (Forense):'
$procs = Get-Process python, node, cargo, app -ErrorAction SilentlyContinue
if ($procs) { 
    foreach ($proc in $procs) { 
        $mem = [math]::Round($proc.WorkingSet64 / 1MB, 2)
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
        $path = if ($cmdLine) { $cmdLine } else { $proc.Path }
        $Report += ('  [ACTIVO] ' + $proc.ProcessName + ' (PID: ' + $proc.Id + ', RAM: ' + $mem + ' MB)')
        $Report += ('    Ruta: ' + $path)
    } 
} else { $Report += '  [LIMPIO] Ningun proceso del ecosistema activo.' }

$Report += ''; $Report += '[4] HARDWARE:'
$cpu = (Get-CimInstance Win32_Processor).LoadPercentage
$ram = [math]::Round(((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize - (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory) / 1MB, 2)
$Report += ('  [CPU] ' + $cpu + '% | [RAM] ' + $ram + ' GB')
$Report += ''; $Report += '========================================='

Write-Host ($Report -join "`r`n") -ForegroundColor Gray
$Report -join "`r`n" | Set-Clipboard
Write-Host "[OK] Reporte copiado al portapapeles." -ForegroundColor Cyan
