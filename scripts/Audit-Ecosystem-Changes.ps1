$ErrorActionPreference = 'Continue'
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$Root = "C:\RUNEFORGE_V2_CORE"

Log "=========================================================="
Log "   AUDITORÍA DE CAMBIOS Y PESO - RUNEFORGE V2"
Log "   Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Log "=========================================================="
Log ""

# ---------------------------------------------------------
# 1. DESGLOSE DE LA CARPETA APPS (¿Quién pesa 5.16 GB?)
# ---------------------------------------------------------
Log "=== 1. DESGLOSE DE CARPETA APPS (Top 10 pesados) ==="
$appsDir = "$Root\apps"
if (Test-Path $appsDir) {
    $appSizes = Get-ChildItem $appsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            Name = $_.Name
            SizeGB = [math]::Round(($size / 1GB), 2)
            SizeMB = [math]::Round(($size / 1MB), 2)
        }
    }
    
    $appSizes | Sort-Object SizeGB -Descending | Select-Object -First 10 | ForEach-Object {
        Log ("{0,-40} : {1,6} GB" -f $_.Name, $_.SizeGB)
    }
} else {
    Log "[!] La carpeta apps no existe."
}
Log ""

# ---------------------------------------------------------
# 2. ANALIZAR LOS NUEVOS SCRIPTS DE PURGA
# ---------------------------------------------------------
Log "=== 2. ANÁLISIS DE NUEVOS SCRIPTS (Primeras 10 líneas) ==="
$newScripts = @(
    "RUNEFORGE_LIGERO_FINAL.ps1",
    "RUNEFORGE_PURGA_DEFINITIVA.ps1",
    "RUNEFORGE_GIT_AMNESIA.ps1",
    "RUNEFORGE_LFS_PURGE.ps1"
)

foreach ($script in $newScripts) {
    $path = "$Root\scripts\$script"
    if (Test-Path $path) {
        Log "--- $script ---"
        $lines = Get-Content $path -TotalCount 10 -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            if ($line.Trim() -ne "") { Log "  $line" }
        }
        Log ""
    }
}

# ---------------------------------------------------------
# 3. REVISAR BACKUPS Y MODIFICACIONES EN OPEN-FRAME-GEN
# ---------------------------------------------------------
Log "=== 3. BACKUPS EN OPEN-FRAME-GEN (ui_overlay.py) ==="
$ofgDir = "$Root\apps\optimizers\Open-Frame-gen\ui"
if (Test-Path $ofgDir) {
    $baks = Get-ChildItem $ofgDir -Filter "ui_overlay.py*" -File | Sort-Object LastWriteTime -Descending
    foreach ($b in $baks) {
        $kb = [math]::Round($b.Length / 1KB, 1)
        Log ("{0,-45} : {1} KB ({2})" -f $b.Name, $kb, $b.LastWriteTime.ToString("MM-dd HH:mm"))
    }
} else {
    Log "No se encontró el directorio de Open-Frame-gen."
}
Log ""

# ---------------------------------------------------------
# 4. ESTADO DE MOSQUITTO Y RECUPERACIÓN
# ---------------------------------------------------------
Log "=== 4. ESTADO DE MOSQUITTO (ESP32) ==="
$svc = Get-Service -Name "mosquitto" -ErrorAction SilentlyContinue
if ($svc) {
    Log "Estado actual: $($svc.Status)"
    if ($svc.Status -ne 'Running') {
        Log "Intentando iniciar el servicio..."
        try {
            Start-Service -Name "mosquitto" -ErrorAction Stop
            Log "[OK] Servicio iniciado correctamente."
        } catch {
            Log "[X] Error al iniciar: $($_.Exception.Message)"
            Log "    (Posiblemente requiere permisos de Administrador)."
        }
    } else {
        Log "[OK] El servicio ya estaba corriendo."
    }
} else {
    Log "[!] El servicio Mosquitto no está instalado."
}
Log ""

# ---------------------------------------------------------
# 5. BUSCAR EJECUTABLES (EXEs) PERDIDOS EN APPS
# ---------------------------------------------------------
Log "=== 5. BUSCANDO EXEs EN CARPETAS LOCALES ==="
$exes = Get-ChildItem "$Root\apps" -Recurse -Filter "*.exe" -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '\\release\\' }
if ($exes) {
    foreach ($exe in $exes) {
        $mb = [math]::Round($exe.Length / 1MB, 2)
        Log ("{0,-50} : {1} MB" -f $exe.Name, $mb)
    }
} else {
    Log "No se encontraron ejecutables en carpetas locales."
}

Log ""
Log "=========================================================="
Log "   FIN DEL REPORTE DE CAMBIOS"
Log "=========================================================="

# Copiar al portapapeles
$FinalText = $Report.ToString()
Set-Clipboard -Value $FinalText
Write-Host ""
Write-Host "[OK] Auditoría de cambios completa. Copiada al portapapeles (Ctrl+V)." -ForegroundColor Green