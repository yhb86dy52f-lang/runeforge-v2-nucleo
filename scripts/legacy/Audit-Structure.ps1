# ==============================================================================
# SCRIPT INTERNO: AUDITORÍA DE ESTRUCTURA (ZERO BLOAT)
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$Message, [string]$Color = "Gray")
    Write-Host $Message -ForegroundColor $Color
    $null = $capture.Add($Message)
}

Log "╔══════════════════════════════════════════════════════╗" "Cyan"
Log "║   AUDITORÍA DE ESTRUCTURA - RUNEFORGE V2 CORE        ║" "Cyan"
Log "╚══════════════════════════════════════════════════════╝" "Cyan"
Log ""

$Root = "C:\RUNEFORGE_V2_CORE"
$ExcludeDirs = @("venv", "node_modules", "target", ".git", "dist", ".sccache", "logs")

# 1. Verificar Carpetas Base
$BaseDirs = @("firmware", "public", "forja", "scripts", "docs", "core_data", "reports")
Log "[1] ESTRUCTURA BASE:"
foreach ($dir in $BaseDirs) {
    if (Test-Path "$Root\$dir") {
        Log "  [OK] $dir\" "Green"
    } else {
        Log "  [X] FALTA CARPETA: $dir\" "Red"
    }
}
Log ""

# 2. Buscar archivos fuera de lugar
Log "[2] ANÁLISIS DE ARCHIVOS (Búsqueda de anomalías):"
$Files = Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $path = $_.FullName
    $isExcluded = $false
    foreach ($ex in $ExcludeDirs) {
        if ($path -match "\\$ex\\") { $isExcluded = $true; break }
    }
    -not $isExcluded
}

$Misplaced = 0

foreach ($file in $Files) {
    $relPath = $file.FullName.Replace("$Root\", "")
    $folder = ($relPath -split '\\')[0]
    
    # Ignorar archivos en la raíz (los evaluaremos aparte)
    if ($folder -eq $relPath) { continue }

    $ext = $file.Extension.ToLower()
    $name = $file.Name.ToLower()
    $expectedFolder = ""

    # Reglas de clasificación
    if ($ext -in @(".ps1", ".bat", ".cmd", ".sh")) { $expectedFolder = "scripts" }
    elseif ($ext -eq ".md" -or $name -match "readme|manual|doc") { $expectedFolder = "docs" }
    elseif ($name -match "index\.html|dashboard\.html|simulador\.html") { $expectedFolder = "public" }
    elseif ($ext -eq ".zip" -or $ext -eq ".7z" -or $ext -eq ".rar") { $expectedFolder = "ARCHIVE (o borrar si es basura)" }
    
    if ($expectedFolder -ne "" -and $folder -ne $expectedFolder) {
        # Excepción: Si estamos en firmware y es un script de hardware (flash, upload), a veces se quedan ahí. 
        # Pero según Zero Bloat, todo script va a scripts.
        Log "  [!] FUERA DE LUGAR: $relPath" "Yellow"
        Log "      -> Debería estar en: $expectedFolder\" "DarkGray"
        $Misplaced++
    }
}

if ($Misplaced -eq 0) {
    Log "  [OK] No se detectaron archivos mal ubicados en subcarpetas." "Green"
}
Log ""

# 3. Archivos sueltos en la RAÍZ
Log "[3] ARCHIVOS EN LA RAÍZ (Deberían estar en carpetas):"
$RootFiles = Get-ChildItem -Path $Root -File -ErrorAction SilentlyContinue
if ($RootFiles) {
    foreach ($rf in $RootFiles) {
        Log "  [!] SUELTO EN RAÍZ: $($rf.Name) ($([math]::Round($rf.Length/1KB, 2)) KB)" "Yellow"
    }
} else {
    Log "  [OK] La raíz está limpia." "Green"
}
Log ""

# 4. Archivos pesados (> 500 KB) fuera de public/firmware
Log "[4] ARCHIVOS PESADOS (Posible bloat):"
$HeavyFiles = $Files | Where-Object { $_.Length -gt 500KB -and $_.DirectoryName -notmatch 'firmware|public|assets' }
if ($HeavyFiles) {
    foreach ($hf in $HeavyFiles) {
        $relPath = $hf.FullName.Replace("$Root\", "")
        Log "  [!] PESADO: $relPath ($([math]::Round($hf.Length/1MB, 2)) MB)" "Magenta"
    }
} else {
    Log "  [OK] No hay archivos innecesariamente pesados." "Green"
}

Log ""
Log "======================================================" "Cyan"
Log " FIN DE LA AUDITORÍA. Revisa las recomendaciones arriba." "Cyan"
Log "======================================================" "Cyan"

$capture | Set-Clipboard