<#
.SYNOPSIS
    Descarga los CDNs referenciados por un HTML y los embebe inline.
.DESCRIPTION
    - Descarga cada CDN a cache persistente (docs\cdn-cache\).
    - Reemplaza <script src="https://..."> por <script>...</script>.
    - Idempotente: si ya estan embebidos, no hace nada.
    - UTF-8 sin BOM.
.PARAMETER HtmlPath
    Ruta absoluta al HTML a procesar.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$HtmlPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $HtmlPath)) { throw "[X] No existe $HtmlPath" }

$cache = "C:\RUNEFORGE_V2_CORE\docs\cdn-cache"
New-Item -ItemType Directory -Path $cache -Force | Out-Null

# --- CDNs a embeber ---
$cdns = @(
    @{ url = "https://cdn.tailwindcss.com";           file = "tailwind.js" },
    @{ url = "https://unpkg.com/lucide@latest";       file = "lucide.js"   },
    @{ url = "https://unpkg.com/mqtt/dist/mqtt.min.js"; file = "mqtt.min.js" }
)

# --- Helper: descargar con fallback ---
function Get-CdnFile {
    param([string]$Url, [string]$Dest)
    Write-Host "  [get] $Url" -ForegroundColor Yellow
    $temp = "$Dest.part"
    if (Test-Path $temp) { Remove-Item $temp -Force -EA SilentlyContinue }

    & curl.exe -L -s -o $temp $Url 2>$null
    if ($LASTEXITCODE -eq 0 -and (Test-Path $temp) -and (Get-Item $temp).Length -gt 1000) {
        Move-Item $temp $Dest -Force
        $kb = [math]::Round((Get-Item $Dest).Length / 1KB, 1)
        Write-Host "  [ok] $kb KB" -ForegroundColor Green
        return $true
    }

    Write-Host "  [!] curl fallo, probando Invoke-WebRequest..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $Url -OutFile $temp -UseBasicParsing
        Move-Item $temp $Dest -Force
        $kb = [math]::Round((Get-Item $Dest).Length / 1KB, 1)
        Write-Host "  [ok] $kb KB" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [X] Fallo: $($_.Exception.Message)" -ForegroundColor Red
        if (Test-Path $temp) { Remove-Item $temp -Force -EA SilentlyContinue }
        return $false
    }
}

# --- PASO 1: Backup ---
Write-Host ""
Write-Host "=== PASO 1/5: Backup ===" -ForegroundColor Cyan
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bak = "$HtmlPath.bak-$stamp"
Copy-Item $HtmlPath $bak -Force
Write-Host "[OK] $bak" -ForegroundColor Green

# --- PASO 2: Descargar CDNs a cache ---
Write-Host ""
Write-Host "=== PASO 2/5: Descargar CDNs a cache ===" -ForegroundColor Cyan
foreach ($cdn in $cdns) {
    $dest = Join-Path $cache $cdn.file
    if (Test-Path $dest) {
        $kb = [math]::Round((Get-Item $dest).Length / 1KB, 1)
        Write-Host "  [--] $($cdn.file) ya esta ($kb KB)" -ForegroundColor DarkGray
        continue
    }
    if (-not (Get-CdnFile -Url $cdn.url -Dest $dest)) {
        throw "[X] No se pudo descargar $($cdn.url)"
    }
}

# --- PASO 3: Leer HTML ---
Write-Host ""
Write-Host "=== PASO 3/5: Leer HTML ===" -ForegroundColor Cyan
$h = [IO.File]::ReadAllText($HtmlPath, [System.Text.UTF8Encoding]::new($false))
$origBytes = $h.Length
$kbOrig = [math]::Round($origBytes / 1KB, 1)
Write-Host "  Original: $kbOrig KB ($origBytes bytes)"

# --- PASO 4: Reemplazar cada CDN por inline ---
Write-Host ""
Write-Host "=== PASO 4/5: Embeber CDNs ===" -ForegroundColor Cyan

$totalInlined = 0
foreach ($cdn in $cdns) {
    $jsPath = Join-Path $cache $cdn.file
    $js = [IO.File]::ReadAllText($jsPath, [System.Text.UTF8Encoding]::new($false))

    $urlEsc = [regex]::Escape($cdn.url)
    $pat = '<script[^>]*\ssrc=["'']' + $urlEsc + '["''][^>]*>\s*</script>'

    $matches = [regex]::Matches($h, $pat, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($matches.Count -eq 0) {
        Write-Host "  [--] $($cdn.url) — sin referencias (ya embebido o no usado)" -ForegroundColor DarkGray
        continue
    }

    foreach ($m in $matches) {
        $inline = "<script>`n/* INLINED-OFFLINE: $($cdn.url) */`n$js`n</script>"
        $h = $h.Replace($m.Value, $inline)
        $totalInlined++
    }
    Write-Host "  [ok] $($cdn.url) -> $($matches.Count) refs embebidas" -ForegroundColor Green
}

if ($totalInlined -eq 0) {
    Write-Host ""
    Write-Host "[--] No habia CDNs por embeber (HTML ya offline-first)" -ForegroundColor DarkGray
}

# --- PASO 5: Escribir y verificar ---
Write-Host ""
Write-Host "=== PASO 5/5: Escribir y verificar ===" -ForegroundColor Cyan
[IO.File]::WriteAllText($HtmlPath, $h, [System.Text.UTF8Encoding]::new($false))

$newBytes = $h.Length
$kbNew = [math]::Round($newBytes / 1KB, 1)
Write-Host "  Nuevo: $kbNew KB ($newBytes bytes)" -ForegroundColor Green

# Verificar que no queden src/href a http(s)
$remaining = [regex]::Matches($h, '(?:src|href)=["'']https?://[^"'']+["'']')
if ($remaining.Count -eq 0) {
    Write-Host ""
    Write-Host "[OK] HTML 100% offline-first (cero refs http/s externas)" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "[!] Aun quedan $($remaining.Count) referencias externas:" -ForegroundColor Yellow
    $remaining | Select-Object -First 10 | ForEach-Object { Write-Host "    $($_.Value)" }
    Write-Host "    (pueden ser comentarios o assets que quieras conservar)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=== FIN ===" -ForegroundColor Green
Write-Host "Backup: $bak" -ForegroundColor Gray
Write-Host "Cache:  $cache" -ForegroundColor Gray