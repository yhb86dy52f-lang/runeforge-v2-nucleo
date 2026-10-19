
# Invoke-Runegea-Root-Restructure.ps1 - v1.1 FIXED (PS5.1 compatible)
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VaultRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$Execute,
    [switch]$NoBackup
)

$ErrorActionPreference = "Stop"
Write-Host @"
  ______  __  __ _   _ ______ _____         _    
 |  __  \| | | | \ | |  ____/ ____|   /\  | |   
 | |  | | | | |  \| | |__ | |  __    /  \ | |   
 | |  | | | | | . ` |  __|| | |_ |  / /\ \| |   
 | |__| | |_| | |\  | |___| |__| | / ____ \_|   
 |_____/ \___/|_| \_|______\_____|/_/    \_(_)   
  RUNEGEA ROOT RESTRUCTURE v1.1 - FIXED PS5.1
"@ -ForegroundColor Magenta

# Auto-detectar root si se ejecuta desde /scripts
if (-not (Test-Path (Join-Path $VaultRoot ".obsidian"))) {
    $VaultRoot = Get-Location
}
if (-not (Test-Path (Join-Path $VaultRoot ".obsidian"))) {
    Write-Host "❌ No encuentro .obsidian en $VaultRoot" -ForegroundColor Red
    Write-Host "   Ejecuta desde la raiz o desde .\scripts\" -ForegroundColor Yellow
    exit 1
}

Write-Host "📂 Vault Root: $VaultRoot" -ForegroundColor Cyan
Write-Host "📂 Script loc: $PSScriptRoot" -ForegroundColor DarkGray
Write-Host "Modo: $(if($Execute){'EJECUCIÓN REAL'}else{'SIMULACIÓN -WhatIf'})" -ForegroundColor $(if($Execute){'Red'}else{'Green'})

# --- 2. BACKUP (FIXED - sin -Exclude, en TEMP) ---
if (-not $NoBackup -and $Execute) {
    $backupName = "BACKUP-RUNEGEA-PRE-RESTRUCTURE-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    $backupPath = Join-Path ([System.IO.Path]::GetTempPath()) $backupName
    Write-Host "💾 Creando backup en TEMP: $backupPath ..." -ForegroundColor Yellow
    try {
        # PS5.1 compatible: no -Exclude, comprimimos * y si existe backup previo en vault lo ignoramos con Where
        $items = Get-ChildItem -Path $VaultRoot -Force | Where-Object { $_.Name -notlike "BACKUP-*.zip" }
        if ($items) {
            Compress-Archive -Path $items.FullName -DestinationPath $backupPath -Force -ErrorAction Stop
            Write-Host "✅ Backup creado: $backupPath" -ForegroundColor Green
            # Copia opcional a raiz para que lo veas
            Copy-Item $backupPath -Destination (Join-Path $VaultRoot $backupName) -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host "⚠️ No se pudo crear backup ZIP: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "   Continuando sin backup..." -ForegroundColor Yellow
    }
}

# --- 3. CREAR ESTRUCTURA FINAL ---
$structure = @(
    "Runeforge",
    "Runeforge\Fleet_Intel",
    "Runeforge\AI_Intel",
    "Runeforge\Quick_Logs",
    "Runeforge\MOCs",
    "Runeforge\Grimorio",
    "Clippings\Runegea",
    "00_Inbox",
    "99_Atlas"
)

foreach ($dir in $structure) {
    $full = Join-Path $VaultRoot $dir
    if (-not (Test-Path $full)) {
        Write-Host "  + Creando $dir" -ForegroundColor DarkGray
        if ($Execute) { New-Item -ItemType Directory -Path $full -Force | Out-Null }
    }
}

function Get-Clasificacion {
    param([string]$Content, [string]$FileName)
    $c = "$Content $FileName".ToLower()
    if ($c -match "rastreo|fleet|flotilla|tgarzaleal|barco|buque|mmsi|ais") {
        return @{ Sello="Purson"; Numero=20; Carpeta="Runeforge\Fleet_Intel"; MOC="Runeforge/MOCs/MOC-Fleet_Intel"; Tags=@("Runegea","Fleet","Purson") }
    }
    if ($c -match "deepseek|chatgpt|claude|gemini|ai|inteligencia artificial|prompt|llm") {
        return @{ Sello="Forneus"; Numero=30; Carpeta="Runeforge\AI_Intel"; MOC="Runeforge/MOCs/MOC-AI_Intel"; Tags=@("Runegea","AI","Forneus") }
    }
    if ($c -match "goetia|grimorio|sello|demonio|purson|forneus|astaroth") {
        return @{ Sello="Astaroth"; Numero=29; Carpeta="Runeforge\Grimorio"; MOC="Runeforge/MOCs/MOC-Grimorio"; Tags=@("Runegea","Goetia") }
    }
    return @{ Sello="Forneus"; Numero=30; Carpeta="Runeforge\Quick_Logs"; MOC="Runeforge/MOCs/MOC-Quick_Logs"; Tags=@("Runegea","QuickLog") }
}

$allMd = Get-ChildItem -Path $VaultRoot -Filter *.md -Recurse | Where-Object { 
    $_.FullName -notlike "*\.obsidian\*" -and 
    $_.FullName -notlike "*\Runeforge\*" -and
    $_.FullName -notlike "*\99_Atlas\*" -and
    $_.FullName -notlike "*\scripts\*" 
}

Write-Host "`n📊 Encontrados $($allMd.Count) archivos fuera de Runeforge para analizar" -ForegroundColor Cyan
$stats = @{ Movidos=0; YaEnSitio=0; HuerfanosForjados=0 }

foreach ($file in $allMd) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    $clas = Get-Clasificacion -Content $content -FileName $file.Name
    $destDir = Join-Path $VaultRoot $clas.Carpeta
    $destPath = Join-Path $destDir $file.Name
    $esHuerfano = -not ($content -match '\[\[.*?\]\]')

    $nuevoFM = @"
---
sello: $($clas.Sello)
sello_numero: $($clas.Numero)
origen: $($file.Directory.Name)
tipo: $($clas.Carpeta.Split('\')[-1])
up: "[[$($clas.MOC)]]"
tags: [$($clas.Tags -join ", ")]
fecha_forja: $(Get-Date -Format "yyyy-MM-dd")
---

> [!RUNE] Sello #$($clas.Numero) $($clas.Sello)
> Forjado desde anillo huérfano -> [[$($clas.MOC)]]

"@

    $cuerpoLimpio = $content -replace '(?s)^---.*?---\s*', ''
    $nuevoContenido = $nuevoFM + "`n" + $cuerpoLimpio.Trim()

    if ($esHuerfano) { $stats.HuerfanosForjados++ }

    if ($file.DirectoryName -ne $destDir) {
        Write-Host "  [MOVER] $($file.Name) -> $($clas.Carpeta) [$($clas.Sello) #$($clas.Numero)]$(if($esHuerfano){' [HUERFANO->FORJADO]'})" -ForegroundColor $(if($esHuerfano){'Yellow'}else{'White'})
        if ($Execute) {
            $nuevoContenido | Set-Content -Path $file.FullName -Encoding UTF8 -Force
            Move-Item -Path $file.FullName -Destination $destPath -Force
            $stats.Movidos++
        }
    } else {
        if ($esHuerfano -and $Execute) {
            $nuevoContenido | Set-Content -Path $file.FullName -Encoding UTF8 -Force
            Write-Host "  [FORJAR] $($file.Name) en sitio -> [[$($clas.MOC)]]" -ForegroundColor Green
        }
        $stats.YaEnSitio++
    }
}

# MOCs
$mocs = @{
    "Runeforge\MOCs\MOC-Fleet_Intel.md" = @"
---
sello: Purson
sello_numero: 20
tipo: MOC
tags: [MOC, Fleet, Purson]
---

# MOC Fleet Intel - Sello #20 Purson
> Purson ve flotas ocultas.

````dataview
TABLE sello, fecha_forja, origen
FROM "Runeforge/Fleet_Intel"
SORT fecha_forja DESC
````
"@
    "Runeforge\MOCs\MOC-AI_Intel.md" = @"
---
sello: Forneus
sello_numero: 30
tipo: MOC
tags: [MOC, AI, Forneus]
---

# MOC AI Intel - Sello #30 Forneus
> Forneus domina lenguajes.

````dataview
TABLE sello, tipo, fecha_forja
FROM "Runeforge/AI_Intel"
SORT fecha_forja DESC
````
"@
    "Runeforge\MOCs\MOC-Quick_Logs.md" = @"
---
sello: Forneus
sello_numero: 30
tipo: MOC
tags: [MOC, QuickLog]
---

# MOC Quick Logs
````dataview
TABLE sello, origen
FROM "Runeforge/Quick_Logs"
SORT file.mtime DESC
````
"@
}

foreach ($mocPath in $mocs.Keys) {
    $fullPath = Join-Path $VaultRoot $mocPath
    if (-not (Test-Path $fullPath)) {
        Write-Host "  + Creando MOC: $mocPath" -ForegroundColor Magenta
        if ($Execute) { $mocs[$mocPath] | Set-Content -Path $fullPath -Encoding UTF8 }
    }
}

Write-Host "`n═══════════════════════════════════════════" -ForegroundColor Magenta
Write-Host " RESUMEN RESTRUCTURE" -ForegroundColor White
Write-Host "═══════════════════════════════════════════" -ForegroundColor Magenta
Write-Host " Analizados: $($allMd.Count)" -ForegroundColor White
Write-Host " Huérfanos forjados: $($stats.HuerfanosForjados)" -ForegroundColor Yellow
Write-Host " Movidos: $($stats.Movidos)" -ForegroundColor Cyan
if (-not $Execute) {
    Write-Host "`n Estabas en SIMULACIÓN. Para real: .\scripts\Invoke-Runegea-Root-Restructure.ps1 -Execute" -ForegroundColor Green
} else {
    Write-Host "`n ✅ REESTRUCTURA COMPLETA." -ForegroundColor Green
}
