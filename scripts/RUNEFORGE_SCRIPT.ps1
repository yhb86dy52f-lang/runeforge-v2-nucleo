# ============================================
# RUNEFORGE V11 - DXCam Cache Clear (Line-by-Line)
# ============================================
$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$m, [string]$c = "White")
    Write-Host $m -ForegroundColor $c
    [void]$capture.Add($m)
}
function LogBlank { Log "" }

Log "===============================================" "Cyan"
Log " RUNEFORGE V11 - DXCam Cache Clear (Line-by-Line)" "Cyan"
Log "===============================================" "Cyan"
Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Gray"
LogBlank

$pyFile = "C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui\ui_overlay.py"

# 1. Backup
Log "[1/4] Creando backup..." "Yellow"
$backup = "$pyFile.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $pyFile $backup -Force
Log "[OK] $backup" "Green"
LogBlank

$lines = @(Get-Content $pyFile -Encoding UTF8)
$changed = $false

# 2. Fix DXCam Cache
Log "[2/4] Aplicando fix de cache DXCam (seguro)..." "Yellow"
$tryIdx = -1
$delIdx = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq 'del cam') {
        for ($j = $i - 1; $j -ge [Math]::Max(0, $i - 10); $j--) {
            if ($lines[$j].Trim() -eq 'try:') { $tryIdx = $j; break }
        }
        if ($tryIdx -ge 0) { $delIdx = $i; break }
    }
}

if ($tryIdx -ge 0 -and $delIdx -ge 0) {
    $createIdx = -1
    for ($i = $delIdx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'cam = dxcam\.create') { $createIdx = $i; break }
    }

    if ($createIdx -ge 0) {
        $indent = $lines[$tryIdx].Length - $lines[$tryIdx].TrimStart().Length
        $indentInner = $indent + 4
        
        $nl = New-Object 'System.Collections.Generic.List[string]'
        
        # Agregar lineas anteriores
        for ($i = 0; $i -lt $tryIdx; $i++) { $nl.Add($lines[$i]) }
        
        # Agregar bloque nuevo (linea por linea, a prueba de fallos)
        $nl.Add((' ' * $indent) + 'try:')
        $nl.Add((' ' * $indentInner) + 'cam.stop()')
        $nl.Add((' ' * $indent) + 'except:')
        $nl.Add((' ' * $indentInner) + 'pass')
        
        $nl.Add((' ' * $indent) + 'try:')
        $nl.Add((' ' * $indentInner) + 'del cam')
        $nl.Add((' ' * $indent) + 'except:')
        $nl.Add((' ' * $indentInner) + 'pass')
        
        $nl.Add((' ' * $indent) + 'import dxcam')
        $nl.Add((' ' * $indent) + 'if hasattr(dxcam, "_factory") and hasattr(dxcam._factory, "cameras"):')
        $nl.Add((' ' * $indentInner) + 'dxcam._factory.cameras.clear()')
        
        $nl.Add((' ' * $indent) + 'cam = dxcam.create(output_idx=1, output_color="BGRA", max_buffer_len=2)')
        
        # Agregar lineas posteriores
        for ($i = $createIdx + 1; $i -lt $lines.Count; $i++) { $nl.Add($lines[$i]) }
        
        $lines = $nl.ToArray()
        $changed = $true
        Log "[OK] Bloque reemplazado con exito (linea por linea)." "Green"
    } else {
        Log "[FAIL] No se encontro cam = dxcam.create." "Red"
    }
} else {
    Log "[FAIL] No se encontro el bloque try / del cam." "Red"
}
LogBlank

if ($changed) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($pyFile, [string[]]$lines, $utf8NoBom)
    Log "[OK] Archivo guardado" "Green"
}

# 3. Validar
Log "[3/4] Validando sintaxis..." "Yellow"
$pyOut = & python -m py_compile $pyFile 2>&1
if ($LASTEXITCODE -eq 0) {
    Log "[OK] Sintaxis VALIDA" "Green"
} else {
    Log "[FAIL] Sintaxis rota. Rollback..." "Red"
    foreach ($l in $pyOut) { Log "  $l" "Red" }
    Copy-Item $backup $pyFile -Force
    Log "[OK] Backup restaurado" "Green"
    $capture | Set-Clipboard
    return
}

# 4. Verificacion
Log "[4/4] Revisando bloque final..." "Yellow"
$check = @(Get-Content $pyFile -Encoding UTF8)
for ($i = $tryIdx; $i -le $tryIdx + 11; $i++) {
    if ($i -lt $check.Count) {
        Log ("  {0,4}: {1}" -f ($i+1), $check[$i]) "DarkGray"
    }
}

LogBlank
Log "===============================================" "Cyan"
Log " FIX COMPLETO" "Cyan"
Log "===============================================" "Cyan"
LogBlank
Log "SIGUIENTE PASO:" "Yellow"
Log "1. Corre el Nano AI:" "White"
Log "   python ui/ui_overlay.py" "Gray"
Log "2. TARGET WINDOW = Monitor 0 / Fullscreen" "White"
Log "3. START AI PIPELINE" "White"
LogBlank
Log "Ya no habra error de 'DXCamera instance already exists'." "Cyan"

$capture | Set-Clipboard
LogBlank
Log "[OK] Reporte copiado al portapapeles (Ctrl+V)." "Cyan"