# =====================================================================
# RUNEFORGE INVENTORY AUDIT V2 SAFE — SOLO LECTURA
# Fecha base: 2026-04-27
# Objetivo:
# - Escanear C:\RUNEFOGE_PRO sin modificar archivos fuente
# - Detectar duplicados por hash
# - Detectar archivos antiguos
# - Detectar posibles secretos SIN imprimir valores
# - Generar reporte CSV/JSON/MD
# =====================================================================

param(
    [string]$BasePath = "C:\RUNEFOGE_PRO",
    [string]$CanonicalRoot = "C:\RUNEFOGE_PRO\runeforge",
    [int]$OldDays = 60,
    [int]$HashMaxMB = 200,
    [string]$OutDir = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (-not (Test-Path -LiteralPath $BasePath)) {
    throw "No existe BasePath: $BasePath"
}

if (-not (Test-Path -LiteralPath $CanonicalRoot)) {
    throw "No existe CanonicalRoot: $CanonicalRoot"
}

if (-not $OutDir) {
    $OutDir = Join-Path $CanonicalRoot "data\audits\inventory_$Stamp"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$ExcludeDirNames = @(
    ".git",
    "node_modules",
    "dist",
    "build",
    ".next",
    "coverage",
    ".venv",
    "venv",
    "__pycache__",
    ".pytest_cache",
    ".turbo"
)

$TextExtensions = @(
    ".ps1",".psm1",".psd1",".js",".ts",".json",".md",".txt",".yml",".yaml",
    ".env",".cmd",".bat",".ahk",".py",".html",".css",".csv",".log"
)

$SecretPatterns = [ordered]@{
    "OPENAI_OR_GENERIC_API_KEY" = "sk-[A-Za-z0-9_\-]{20,}"
    "BEARER_TOKEN"             = "Bearer\s+[A-Za-z0-9\._\-]{20,}"
    "JWT"                      = "eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+"
    "PASSWORD_ASSIGNMENT"      = "(?i)(password|passwd|pwd)\s*[:=]\s*\S{6,}"
    "TOKEN_ASSIGNMENT"         = "(?i)(token|api_key|apikey|secret)\s*[:=]\s*\S{8,}"
    "PRIVATE_KEY_BLOCK"        = "-----BEGIN .*PRIVATE KEY-----"
}

function Test-IsExcludedPath {
    param([string]$FullName)

    if ([string]::IsNullOrWhiteSpace($FullName)) {
        return $false
    }

    $parts = $FullName -split '[\\/]'

    foreach ($name in $ExcludeDirNames) {
        if ($parts -contains $name) {
            return $true
        }
    }

    return $false
}

function Get-FilesSafe {
    param([string]$RootPath)

    $stack = [System.Collections.Generic.Stack[string]]::new()
    $stack.Push($RootPath)

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()

        Get-ChildItem -LiteralPath $current -File -Force -ErrorAction SilentlyContinue

        $dirs = Get-ChildItem -LiteralPath $current -Directory -Force -ErrorAction SilentlyContinue
        foreach ($dir in $dirs) {
            if ($ExcludeDirNames -contains $dir.Name) {
                continue
            }

            if (-not (Test-IsExcludedPath -FullName $dir.FullName)) {
                $stack.Push($dir.FullName)
            }
        }
    }
}

function Get-Category {
    param(
        [string]$FullName,
        [string]$Extension
    )

    $p = $FullName.ToLowerInvariant()
    $e = $Extension.ToLowerInvariant()

    if ($p -match "runeforge|commander|forge|sentinel|codex|beacon|anvil|trace") { return "RuneforgeCore" }
    if ($p -match "cctv|dahua|hikvision|epcom|camera|camara|nvr|dvr") { return "CCTV" }
    if ($p -match "calamp|wialon|traccar|ruptela|escort|td-600|td600|td-500|gps|telemet") { return "Telemetria" }
    if ($p -match "hardening|ssh|tailscale|firewall|defender|security|seguridad") { return "Hardening" }
    if ($p -match "bitacora|falla|incidente|reporte|log") { return "Bitacoras" }
    if ($p -match "lab|laboratorio|test|prueba|experiment") { return "Laboratorio" }
    if ($p -match "memoria|prompt|ia|gpt|gemini|claude|context") { return "MemoriaIA" }
    if ($p -match "script|automation|automatizacion|powershell|python|ahk") { return "Automatizacion" }

    if ($e -in @(".ps1",".psm1",".py",".js",".ts",".ahk",".cmd",".bat")) { return "Codigo" }
    if ($e -in @(".md",".txt",".pdf",".docx")) { return "Documentacion" }
    if ($e -in @(".json",".csv",".sqlite",".db",".yaml",".yml")) { return "Datos" }
    if ($e -in @(".log",".evtx")) { return "Logs" }

    return "Otro"
}

function Get-SafeHash {
    param([System.IO.FileInfo]$File)

    try {
        if ($File.Length -le 0) { return "" }

        $maxBytes = $HashMaxMB * 1MB
        if ($File.Length -gt $maxBytes) {
            return "SKIPPED_GT_${HashMaxMB}MB"
        }

        return (Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
    }
    catch {
        return "HASH_ERROR"
    }
}

function Search-SecretIndicators {
    param([System.IO.FileInfo]$File)

    $hits = @()

    try {
        if ($File.Extension.ToLowerInvariant() -notin $TextExtensions) { return $hits }
        if ($File.Length -gt 2MB) { return $hits }

        $raw = Get-Content -LiteralPath $File.FullName -Raw -ErrorAction Stop

        foreach ($key in $SecretPatterns.Keys) {
            if ($raw -match $SecretPatterns[$key]) {
                $hits += [pscustomobject]@{
                    Pattern = $key
                    Path    = $File.FullName
                    SizeKB  = [math]::Round($File.Length / 1KB, 2)
                    Note    = "Indicador detectado. Valor NO impreso por seguridad."
                }
            }
        }
    }
    catch {
        $hits += [pscustomobject]@{
            Pattern = "READ_ERROR"
            Path    = $File.FullName
            SizeKB  = [math]::Round($File.Length / 1KB, 2)
            Note    = $_.Exception.Message
        }
    }

    return $hits
}

Write-Host "[RUNEFORGE] Inventario solo lectura iniciado" -ForegroundColor Cyan
Write-Host "BasePath      = $BasePath" -ForegroundColor DarkCyan
Write-Host "CanonicalRoot = $CanonicalRoot" -ForegroundColor DarkCyan
Write-Host "OutDir        = $OutDir" -ForegroundColor DarkCyan

$AllFiles = @(Get-FilesSafe -RootPath $BasePath)

$Inventory = New-Object System.Collections.Generic.List[object]
$SecretHits = New-Object System.Collections.Generic.List[object]

$Total = $AllFiles.Count
$Index = 0

foreach ($file in $AllFiles) {
    $Index++

    if (($Index % 250) -eq 0) {
        Write-Host "  Procesados: $Index / $Total" -ForegroundColor DarkGray
    }

    $relative = $file.FullName.Replace($BasePath, "").TrimStart("\")
    $category = Get-Category -FullName $file.FullName -Extension $file.Extension

    $Inventory.Add([pscustomobject]@{
        Name          = $file.Name
        Extension     = $file.Extension.ToLowerInvariant()
        Category      = $category
        FullPath      = $file.FullName
        RelativePath  = $relative
        Directory     = $file.DirectoryName
        SizeBytes     = $file.Length
        SizeMB        = [math]::Round($file.Length / 1MB, 3)
        Created       = $file.CreationTime
        LastWrite     = $file.LastWriteTime
        AgeDays       = [math]::Round(((Get-Date) - $file.LastWriteTime).TotalDays, 1)
        IsOld         = $file.LastWriteTime -lt (Get-Date).AddDays(-1 * $OldDays)
        IsCanonical   = $file.FullName.StartsWith($CanonicalRoot, [System.StringComparison]::OrdinalIgnoreCase)
        Hash          = ""
    })

    foreach ($hit in (Search-SecretIndicators -File $file)) {
        $SecretHits.Add($hit)
    }
}

Write-Host "[RUNEFORGE] Calculando hashes para candidatos a duplicado..." -ForegroundColor Cyan

$BySize = $Inventory |
    Where-Object { $_.SizeBytes -gt 0 -and $_.SizeMB -le $HashMaxMB } |
    Group-Object SizeBytes |
    Where-Object { $_.Count -gt 1 }

foreach ($group in $BySize) {
    foreach ($item in $group.Group) {
        try {
            $fi = Get-Item -LiteralPath $item.FullPath -ErrorAction Stop
            $item.Hash = Get-SafeHash -File $fi
        }
        catch {
            $item.Hash = "HASH_ERROR"
        }
    }
}

$Duplicates = $Inventory |
    Where-Object { $_.Hash -and $_.Hash -notmatch "^(SKIPPED|HASH_ERROR)$" } |
    Group-Object Hash |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object {
        $hash = $_.Name
        $rank = 0

        $ordered = $_.Group | Sort-Object -Property `
            @{ Expression = { $_.IsCanonical }; Descending = $true }, `
            @{ Expression = { $_.LastWrite }; Descending = $true }

        foreach ($f in $ordered) {
            $rank++
            [pscustomobject]@{
                Hash        = $hash
                DuplicateNo = $rank
                KeepHint    = if ($rank -eq 1) { "KEEP_CANDIDATE" } else { "DUPLICATE_REVIEW" }
                Category    = $f.Category
                Name        = $f.Name
                FullPath    = $f.FullPath
                SizeMB      = $f.SizeMB
                LastWrite   = $f.LastWrite
                IsCanonical = $f.IsCanonical
            }
        }
    }

$OldFiles = $Inventory |
    Where-Object { $_.IsOld -eq $true } |
    Sort-Object LastWrite

$CategorySummary = $Inventory |
    Group-Object Category |
    Sort-Object Count -Descending |
    Select-Object Count, Name

$RootSummary = Get-ChildItem -LiteralPath $BasePath -Directory -ErrorAction SilentlyContinue |
    ForEach-Object {
        $path = $_.FullName
        $files = @($Inventory | Where-Object { $_.FullPath.StartsWith($path, [System.StringComparison]::OrdinalIgnoreCase) })
        $sum = ($files | Measure-Object SizeBytes -Sum).Sum
        if ($null -eq $sum) { $sum = 0 }

        $latest = $null
        if ($files.Count -gt 0) {
            $latest = ($files | Sort-Object LastWrite -Descending | Select-Object -First 1).LastWrite
        }

        [pscustomobject]@{
            Folder       = $_.Name
            Path         = $path
            Files        = $files.Count
            SizeMB       = [math]::Round($sum / 1MB, 2)
            LatestWrite  = $latest
            CanonicalHit = $path.Equals($CanonicalRoot, [System.StringComparison]::OrdinalIgnoreCase)
        }
    } |
    Sort-Object LatestWrite -Descending

$InventoryPath = Join-Path $OutDir "inventory_files.csv"
$DuplicatePath = Join-Path $OutDir "duplicates_by_hash.csv"
$OldPath = Join-Path $OutDir "old_files.csv"
$SecretPath = Join-Path $OutDir "secret_indicators.csv"
$RootPath = Join-Path $OutDir "root_summary.csv"
$SummaryPath = Join-Path $OutDir "summary.json"
$ReportPath = Join-Path $OutDir "REPORT.md"

$Inventory | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $InventoryPath
$Duplicates | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $DuplicatePath
$OldFiles | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $OldPath
$SecretHits | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $SecretPath
$RootSummary | Export-Csv -NoTypeInformation -Encoding UTF8 -LiteralPath $RootPath

$Summary = [ordered]@{
    Fecha              = (Get-Date).ToString("o")
    BasePath           = $BasePath
    CanonicalRoot      = $CanonicalRoot
    OutDir             = $OutDir
    TotalFiles         = $Inventory.Count
    TotalSizeMB        = [math]::Round((($Inventory | Measure-Object SizeBytes -Sum).Sum) / 1MB, 2)
    OldDaysThreshold   = $OldDays
    OldFiles           = @($OldFiles).Count
    DuplicateFiles     = @($Duplicates).Count
    SecretIndicators   = $SecretHits.Count
    Categories         = $CategorySummary
    RootFolders        = $RootSummary
}

$SummaryObj = [pscustomobject]$Summary
$SummaryObj | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $SummaryPath -Encoding UTF8

$TopFoldersMd = ($RootSummary | Select-Object -First 20 | ForEach-Object {
    "| $($_.Folder) | $($_.Files) | $($_.SizeMB) | $($_.LatestWrite) | $($_.CanonicalHit) |"
}) -join "`r`n"

$CategoriesMd = ($CategorySummary | ForEach-Object {
    "| $($_.Name) | $($_.Count) |"
}) -join "`r`n"

$Report = @"
# RUNEFORGE INVENTORY AUDIT V2 SAFE

Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
BasePath: $BasePath
CanonicalRoot: $CanonicalRoot

## Veredicto rápido

- Total archivos: $($SummaryObj.TotalFiles)
- Peso total MB: $($SummaryObj.TotalSizeMB)
- Archivos antiguos > $OldDays días: $($SummaryObj.OldFiles)
- Duplicados detectados por hash: $($SummaryObj.DuplicateFiles)
- Indicadores posibles de secreto: $($SummaryObj.SecretIndicators)

## Carpetas raíz

| Carpeta | Archivos | MB | Última modificación | Es canónica |
|---|---:|---:|---|---|
$TopFoldersMd

## Categorías detectadas

| Categoría | Archivos |
|---|---:|
$CategoriesMd

## Archivos generados

- inventory_files.csv
- duplicates_by_hash.csv
- old_files.csv
- secret_indicators.csv
- root_summary.csv
- summary.json

## Regla operativa

Este reporte es SOLO LECTURA.
No se borró, movió ni modificó ningún archivo fuente.

## Siguiente acción recomendada

1. Revisar secret_indicators.csv primero.
2. Revisar duplicates_by_hash.csv.
3. Revisar root_summary.csv para decidir carpeta activa.
4. Migrar solo lo validado hacia docs/data/scripts/lab.
5. Archivar legado en archive/legacy después de respaldo.
"@

Set-Content -LiteralPath $ReportPath -Value $Report -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "RUNEFORGE INVENTORY AUDIT COMPLETADO" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

[pscustomobject]@{
    Estado            = "AUDIT_OK_SOLO_LECTURA"
    BasePath          = $BasePath
    CanonicalRoot     = $CanonicalRoot
    OutDir            = $OutDir
    TotalFiles        = $SummaryObj.TotalFiles
    TotalSizeMB       = $SummaryObj.TotalSizeMB
    OldFiles          = $SummaryObj.OldFiles
    DuplicateFiles    = $SummaryObj.DuplicateFiles
    SecretIndicators  = $SummaryObj.SecretIndicators
    Report            = $ReportPath
} | Format-List

Write-Host "[OK] Reporte principal: $ReportPath" -ForegroundColor Cyan
Write-Host "[REGLA] Solo lectura. No se modificó ningún archivo fuente." -ForegroundColor Yellow
