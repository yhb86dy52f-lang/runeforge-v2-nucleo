$ErrorActionPreference = 'Continue'
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$Root = "C:\RUNEFORGE_V2_CORE"

Log "=========================================================="
Log "   AUDITORÍA DEL ECOSISTEMA RUNEFORGE V2"
Log "   Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log "=========================================================="
Log ""

# ---------------------------------------------------------
# 1. ANÁLISIS DE ALMACENAMIENTO (TOP CARPETAS PESADAS)
# ---------------------------------------------------------
Log "=== 1. CONSUMO DE DISCO EN DIRECTORIOS CLAVE ==="
$paths = @(
    "$Root\target",
    "$Root\node_modules",
    "$Root\whisper-backend\venv",
    "$Root\whisper.cpp",
    "$Root\ollama",
    "$Root\apps",
    "$Root\_archived_backups_20261018",
    "$Root\_archived_backups_20261018_194836",
    "$Root\_archived_backups_20261018_195003"
)

foreach ($p in $paths) {
    if (Test-Path $p) {
        try {
            $size = (Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            if ($size -eq $null) { $size = 0 }
            $sizeGB = [math]::Round(($size / 1GB), 2)
            Log ("{0,-65} : {1,8} GB" -f $p.Replace("$Root\", ""), $sizeGB)
        } catch {
            Log "[!] No se pudo medir: $p"
        }
    } else {
        Log ("{0,-65} : [NO EXISTE]" -f $p.Replace("$Root\", ""))
    }
}
Log ""

# ---------------------------------------------------------
# 2. ARCHIVOS MODIFICADOS RECIENTEMENTE (EXCLUYENDO BLOAT)
# ---------------------------------------------------------
Log "=== 2. ÚLTIMOS 15 ARCHIVOS MODIFICADOS (Omitiendo node_modules y target) ==="
$exclude = @("node_modules", "target", ".git", "__pycache__", "venv", "whisper.cpp")
$recentFiles = Get-ChildItem $Root -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $path = $_.FullName
        $isExcluded = $false
        foreach ($ex in $exclude) {
            if ($path -match "\\$ex\\" -or $path -match "\\$ex$") { $isExcluded = $true; break }
        }
        -not $isExcluded -and $_.LastWriteTime -gt (Get-Date).AddDays(-3)
    } | Sort-Object LastWriteTime -Descending | Select-Object -First 15

if ($recentFiles) {
    foreach ($f in $recentFiles) {
        $relPath = $f.FullName.Replace("$Root\", "")
        Log ("[{0}] {1}" -f $f.LastWriteTime.ToString("MM-dd HH:mm"), $relPath)
    }
} else {
    Log "No hay archivos modificados en los últimos 3 días (fuera de compilaciones)."
}
Log ""

# ---------------------------------------------------------
# 3. PROCESOS Y SERVICIOS ACTIVOS
# ---------------------------------------------------------
Log "=== 3. PROCESOS Y SERVICIOS DEL ECOSISTEMA ==="
$procNames = @("python", "node", "mosquitto", "ollama", "tailscale", "pm2", "dictate-studio-v2")
$activeProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $procNames -contains $_.ProcessName }
if ($activeProcs) {
    $activeProcs | Group-Object ProcessName | ForEach-Object {
        $mem = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2)
        Log ("Proceso: {0,-20} | Instancias: {1} | RAM: {2} MB" -f $_.Name, $_.Count, $mem)
    }
} else {
    Log "No hay procesos del ecosistema corriendo actualmente."
}

$services = @("mosquitto", "tailscale")
foreach ($svc in $services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        Log ("Servicio: {0,-20} | Estado: {1}" -f $s.Name, $s.Status)
    } else {
        Log ("Servicio: {0,-20} | [NO INSTALADO]" -f $svc)
    }
}
Log ""

# ---------------------------------------------------------
# 4. VERIFICACIÓN DE APLICACIONES COMPILADAS (.EXE)
# ---------------------------------------------------------
Log "=== 4. APLICACIONES (EXEs) EN TARGET/RELEASE ==="
$releaseDir = "$Root\target\release"
if (Test-Path $releaseDir) {
    $exes = Get-ChildItem $releaseDir -Filter "*.exe" -File -ErrorAction SilentlyContinue
    if ($exes) {
        foreach ($exe in $exes) {
            $sizeMB = [math]::Round($exe.Length / 1MB, 2)
            Log ("{0,-40} : {1} MB (Mod: {2})" -f $exe.Name, $sizeMB, $exe.LastWriteTime.ToString("yyyy-MM-dd"))
        }
    } else {
        Log "No se encontraron ejecutables en target\release."
    }
} else {
    Log "[!] No existe el directorio target\release."
}

Log ""
Log "=========================================================="
Log "   FIN DEL REPORTE DE AUDITORÍA"
Log "=========================================================="

# Copiar al portapapeles
$FinalText = $Report.ToString()
Set-Clipboard -Value $FinalText
Write-Host ""
Write-Host "[OK] Auditoría completa. Salida copiada al portapapeles (Ctrl+V)." -ForegroundColor Green