# =====================================================================
# RUNEFORGE MULTI-PROJECT COMPARATOR
# Fecha: 2026-04-27
# Objetivo: Comparar TODAS las carpetas de proyecto en C:\RUNEFOGE_PRO
# y determinar cuál es la más actualizada, sólida y segura.
# Regla: SOLO LECTURA.
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Fecha = Get-Date -Format "yyyy-MM-dd_HHmmss"
$Root = "C:\RUNEFOGE_PRO\runeforge"
$OutDir = Join-Path $Root "data\audits\multi_project_comparison_$Fecha"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$BasePath = "C:\RUNEFOGE_PRO"

# =====================================================================
# FUNCIÓN: Huella digital de un proyecto
# =====================================================================

function Get-ProjectFingerprint {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }

    $Name = Split-Path $Path -Leaf

    $Files = Get-ChildItem $Path -Recurse -File -ErrorAction SilentlyContinue
    $TotalFiles = $Files.Count
    $TotalSizeMB = if ($TotalFiles -gt 0) { [math]::Round(($Files | Measure-Object Length -Sum).Sum / 1MB, 2) } else { 0 }

    $LastModified = if ($TotalFiles -gt 0) { ($Files | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime } else { Get-ChildItem $Path | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { $_.LastWriteTime } }

    $ModifiedToday = ($Files | Where-Object { $_.LastWriteTime -ge (Get-Date).Date }).Count

    $KeyFolders = @("app", "scripts", "docs", "data", "backups")
    $FolderCount = ($KeyFolders | Where-Object { Test-Path (Join-Path $Path $_) }).Count

    # ¿Tiene .gitignore con .env?
    $Gitignore = Join-Path $Path ".gitignore"
    $EnvProtected = $false
    if (Test-Path $Gitignore) {
        $EnvProtected = (Get-Content $Gitignore -Raw) -match "\.env"
    }

    # ¿Server.js con host bind seguro?
    $ServerJs = Get-ChildItem (Join-Path $Path "app\src\server.js") -ErrorAction SilentlyContinue | Select-Object -First 1
    $HostBindSafe = $false
    if ($ServerJs -and (Test-Path $ServerJs.FullName)) {
        $Content = Get-Content $ServerJs.FullName -Raw -ErrorAction SilentlyContinue
        $HostBindSafe = ($Content -match "host") -and ($Content -match "127\.0\.0\.1")
    }

    # ¿Tiene panel AHK?
    $AhkPanel = Get-ChildItem (Join-Path $Path "scripts\ahk\RUNEFORGE_COMMANDER_*.ahk") -ErrorAction SilentlyContinue | Select-Object -First 1
    $HasPanel = $AhkPanel -ne $null

    return [pscustomobject]@{
        Nombre         = $Name
        Ruta           = $Path
        Archivos       = $TotalFiles
        PesoMB         = $TotalSizeMB
        UltimaMod      = $LastModified
        ModHoy         = $ModifiedToday
        CarpetasClave  = $FolderCount
        EnvProtegido   = $EnvProtected
        HostBindSeguro = $HostBindSafe
        PanelAHK       = $HasPanel
    }
}

# =====================================================================
# ESCANEAR TODAS LAS CARPETAS EN C:\RUNEFOGE_PRO
# =====================================================================

Write-Host "Escaneando: $BasePath" -ForegroundColor Cyan

$Projects = Get-ChildItem $BasePath -Directory | Where-Object {
    $_.Name -match "runeforge|essential|lab|diagnostico|memoria|datahub" -or
    $_.Name -eq "runeforge-mvp" -or
    $_.Name -eq "runeforge-v2-ready"
}

Write-Host "Se encontraron $($Projects.Count) carpetas de proyecto." -ForegroundColor Yellow

$Fingerprints = @()
foreach ($proj in $Projects) {
    Write-Host "  -> $($proj.Name)" -ForegroundColor White
    $fp = Get-ProjectFingerprint -Path $proj.FullName
    if ($fp) { $Fingerprints += $fp }
}

# =====================================================================
# PUNTUACIÓN
# =====================================================================

function Get-ProjectScore {
    param($P)
    $Score = 0
    if ($P.ModHoy -gt 0) { $Score += 3 }
    if ($P.CarpetasClave -ge 3) { $Score += 2 }
    if ($P.CarpetasClave -ge 4) { $Score += 2 }
    if ($P.EnvProtegido) { $Score += 1 }
    if ($P.HostBindSeguro) { $Score += 2 }
    if ($P.PanelAHK) { $Score += 1 }
    if ($P.UltimaMod -and ($P.UltimaMod -ge (Get-Date).AddDays(-7))) { $Score += 2 }
    if ($P.Archivos -gt 10) { $Score += 1 }
    return $Score
}

$Scored = @()
foreach ($fp in $Fingerprints) {
    $Score = Get-ProjectScore $fp
    $fp | Add-Member -NotePropertyName Score -NotePropertyValue $Score
    $Scored += $fp
}

$Scored = $Scored | Sort-Object Score -Descending

# =====================================================================
# RESULTADOS
# =====================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "🏆 RANKING DE PROYECTOS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$Scored | Select-Object Score, Nombre, Archivos, PesoMB, CarpetasClave, EnvProtegido, HostBindSeguro, PanelAHK, UltimaMod | Format-Table -AutoSize

Write-Host ""
Write-Host "🏅 GANADOR: $($Scored[0].Nombre) — Score: $($Scored[0].Score)" -ForegroundColor Green
Write-Host "Ruta: $($Scored[0].Ruta)" -ForegroundColor Green

if ($Scored.Count -gt 1) {
    Write-Host ""
    Write-Host "🥈 SEGUNDO: $($Scored[1].Nombre) — Score: $($Scored[1].Score)" -ForegroundColor Yellow
    Write-Host "Ruta: $($Scored[1].Ruta)" -ForegroundColor Yellow
}

# =====================================================================
# EXPORTAR
# =====================================================================

$ExportPath = Join-Path $OutDir "multi-project-ranking.json"
$Scored | ConvertTo-Json -Depth 3 | Out-File $ExportPath -Encoding utf8

Write-Host ""
Write-Host "[OK] Ranking exportado: $ExportPath" -ForegroundColor Cyan
Write-Host "[REGLA] Solo lectura. Ningún proyecto modificado." -ForegroundColor Yellow
