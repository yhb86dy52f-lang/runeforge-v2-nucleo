
# Invoke-Runegea-Root-Restructure.ps1
# MASTER REESTRUCTURADOR - Ejecutar desde la RAIZ del vault Obsidian
# Ubicación: C:\TuVault\Invoke-Runegea-Root-Restructure.ps1
# Uso: .\Invoke-Runegea-Root-Restructure.ps1 -WhatIf  (simula) 
#      .\Invoke-Runegea-Root-Restructure.ps1 -Execute (ejecuta real)

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$VaultRoot = (Get-Location).Path,
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
  RUNEGEA ROOT RESTRUCTURE v1.0
"@ -ForegroundColor Magenta

# --- 1. DETECTAR VAULT ROOT ---
if (-not (Test-Path (Join-Path $VaultRoot ".obsidian"))) {
    Write-Host "❌ No encuentro .obsidian en $VaultRoot" -ForegroundColor Red
    Write-Host "   Asegúrate de ejecutar este script DESDE LA RAÍZ del vault." -ForegroundColor Yellow
    Write-Host "   Ej: cd C:\RunegeaVault; .\Invoke-Runegea-Root-Restructure.ps1 -WhatIf" -ForegroundColor Yellow
    exit 1
}

Write-Host "📂 Vault Root: $VaultRoot" -ForegroundColor Cyan
Write-Host "Modo: $(if($Execute){'EJECUCIÓN REAL'}else{'SIMULACIÓN -WhatIf'})" -ForegroundColor $(if($Execute){'Red'}else{'Green'})

# --- 2. BACKUP ---
if (-not $NoBackup -and $Execute) {
    $backupName = "BACKUP-RUNEGEA-PRE-RESTRUCTURE-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    $backupPath = Join-Path $VaultRoot $backupName
    Write-Host "💾 Creando backup: $backupName ..." -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($backupPath, "Crear Backup ZIP")) {
        Compress-Archive -Path "$VaultRoot\*" -DestinationPath $backupPath -Exclude $backupName -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Backup creado" -ForegroundColor Green
    }
}

# --- 3. CREAR ESTRUCTURA FINAL (Arquitectura Purson-Forneus) ---
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

# --- 4. FUNCION DE CLASIFICACION POR SELLO ---
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

# --- 5. ESCANEAR Y MOVER ---
$allMd = Get-ChildItem -Path $VaultRoot -Filter *.md -Recurse | Where-Object { $_.FullName -notlike "*\.obsidian\*" -and $_.FullName -notlike "*\Runeforge\*" -and $_.FullName -notlike "*\00_Inbox\*" }

Write-Host "`n📊 Encontrados $($allMd.Count) archivos fuera de Runeforge para analizar" -ForegroundColor Cyan

$stats = @{ Movidos=0; YaEnSitio=0; HuerfanosForjados=0 }

foreach ($file in $allMd) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    $clas = Get-Clasificacion -Content $content -FileName $file.Name
    $destDir = Join-Path $VaultRoot $clas.Carpeta
    $destPath = Join-Path $destDir $file.Name

    # Detectar huérfano (sin [[link]])
    $esHuerfano = -not ($content -match '\[\[.*?\]\]')

    # Generar nuevo frontmatter limpio y forjado
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

    # Limpiar contenido viejo (quitar frontmatter roto si existe)
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
        # Ya está en sitio pero hay que forjar frontmatter si es huérfano
        if ($esHuerfano -and $Execute) {
            $nuevoContenido | Set-Content -Path $file.FullName -Encoding UTF8 -Force
            Write-Host "  [FORJAR] $($file.Name) en sitio -> [[$($clas.MOC)]]" -ForegroundColor Green
        }
        $stats.YaEnSitio++
    }
}

# --- 6. CREAR MOCs MAESTROS (Si no existen) ---
$mocs = @{
    "Runeforge\MOCs\MOC-Fleet_Intel.md" = @"
---
sello: Purson
sello_numero: 20
tipo: MOC
tags: [MOC, Fleet, Purson]
---

# MOC Fleet Intel - Sello #20 Purson

> Purson ve flotas ocultas. Todo rastreo va aquí.

## Dataview - Todo Fleet
````dataview
TABLE sello, fecha_forja, origen
FROM "Runeforge/Fleet_Intel"
SORT fecha_forja DESC
````

## Graph local
````dataview
LIST FROM [[Runeforge/MOCs/MOC-Fleet_Intel]]
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

> Forneus domina lenguajes. DeepSeek, ChatGPT, Claude van aquí.

## Dataview - Todo AI
````dataview
TABLE sello, tipo, fecha_forja
FROM "Runeforge/AI_Intel"
SORT fecha_forja DESC
````

## Clippings recientes
````dataview
TABLE file.mtime as modificado
FROM "Runeforge/AI_Intel"
WHERE contains(tags, "Forneus")
SORT file.mtime DESC
LIMIT 20
````
"@
    "Runeforge\MOCs\MOC-Quick_Logs.md" = @"
---
sello: Forneus
sello_numero: 30
tipo: MOC
tags: [MOC, QuickLog]
---

# MOC Quick Logs - Inbox Forjado

Notas rápidas y clippings sin clasificar que ya fueron forjados del anillo amarillo.

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
        if ($Execute) {
            $mocs[$mocPath] | Set-Content -Path $fullPath -Encoding UTF8
        }
    }
}

# --- 7. RESUMEN FINAL ---
Write-Host "`n" -NoNewline
Write-Host "═══════════════════════════════════════════" -ForegroundColor Magenta
Write-Host " RESUMEN RESTRUCTURE" -ForegroundColor White
Write-Host "═══════════════════════════════════════════" -ForegroundColor Magenta
Write-Host " Archivos analizados: $($allMd.Count)" -ForegroundColor White
Write-Host " Huérfanos forjados (anillo amarillo): $($stats.HuerfanosForjados)" -ForegroundColor Yellow
Write-Host " Movidos: $($stats.Movidos)" -ForegroundColor Cyan
Write-Host " Ya en sitio: $($stats.YaEnSitio)" -ForegroundColor Gray
Write-Host ""
if (-not $Execute) {
    Write-Host " Estabas en modo SIMULACIÓN." -ForegroundColor Green
    Write-Host " Para ejecutar real: .\Invoke-Runegea-Root-Restructure.ps1 -Execute" -ForegroundColor Green
} else {
    Write-Host " ✅ REESTRUCTURA COMPLETA. Reinicia Obsidian." -ForegroundColor Green
    Write-Host " Ve a Graph View > Settings > Groups y añade:" -ForegroundColor Yellow
    Write-Host "   Group1: sello:Purson -> Blue" -ForegroundColor Blue
    Write-Host "   Group2: sello:Forneus -> Purple" -ForegroundColor Magenta
}
