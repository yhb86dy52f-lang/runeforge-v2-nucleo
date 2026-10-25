
# Get-Runegea-Validacion-Bodega.ps1
# OBJETIVO: Validar donde esta realmente la bodega/load sin asumir nada
# USO: cd a donde creas que esta tu vault y ejecuta: .\Get-Runegea-Validacion-Bodega.ps1
# No necesita parametros, detecta todo solo.

$Root = (Get-Location).Path
$ReportPath = Join-Path $env:TEMP "validacion-runegea-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

Write-Host "🔍 VALIDACION REAL - Sin suposiciones" -ForegroundColor Magenta
Write-Host "Escaneando desde: $Root" -ForegroundColor Cyan
Write-Host ""

$report = @()
$report += "=== VALIDACION RUNEGEA BODEGA ==="
$report += "Fecha: $(Get-Date)"
$report += "Root escaneado: $Root"
$report += ""

# 1. ¿Donde esta .obsidian? -> ese es el vault real
$report += "--- 1. VAULTS REALES (.obsidian) ---"
$vaults = Get-ChildItem -Path $Root -Filter ".obsidian" -Directory -Force -Recurse -Depth 4 -ErrorAction SilentlyContinue
if ($vaults) {
    foreach ($v in $vaults) {
        $report += "VAULT EN: $($v.Parent.FullName)"
        Write-Host "✅ VAULT EN: $($v.Parent.FullName)" -ForegroundColor Green
    }
} else {
    $report += "NO se encontro .obsidian en $Root ni subcarpetas (4 niveles)"
    Write-Host "❌ No hay .obsidian aqui" -ForegroundColor Red
}
$report += ""

# 2. Estructura nivel 1 y 2 - conteo de .md
$report += "--- 2. ESTRUCTURA Y CONTEO .md (Nivel 1) ---"
$topDirs = Get-ChildItem -Path $Root -Directory -Force -ErrorAction SilentlyContinue
foreach ($d in $topDirs) {
    $count = (Get-ChildItem -Path $d.FullName -Filter *.md -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $isLink = ""
    if ($d.LinkType) { $isLink = " [LINK-> $($d.Target)]" }
    # Detectar Junction/Symlink (como conectaste la bodega)
    $attr = (Get-Item $d.FullName -Force).Attributes
    $line = "$($d.Name) : $count .md$isLink"
    $report += $line
    if ($count -gt 100) {
        Write-Host "📦 $line" -ForegroundColor Yellow
    } else {
        Write-Host "📁 $line" -ForegroundColor Gray
    }
}
$report += ""

# 3. Archivos .md sueltos en raiz (causa del anillo amarillo)
$report += "--- 3. .md SUELTOS EN RAIZ ---"
$sueltos = Get-ChildItem -Path $Root -Filter *.md -File -Force -ErrorAction SilentlyContinue
$report += "En raiz directa: $($sueltos.Count) archivos .md"
Write-Host "En raiz: $($sueltos.Count) .md sueltos" -ForegroundColor $(if($sueltos.Count -gt 50){'Red'}else{'Green'})
$sueltos | Select-Object -First 30 | ForEach-Object { $report += " - $($_.Name)" }
$report += ""

# 4. Busqueda especifica de BODEGA / LOAD / BEYOND / B2 / etc sin asumir nombre
$report += "--- 4. BUSQUEDA DE CANDIDATOS A BODEGA (por patron) ---"
$patterns = @("*bodega*","*Bodega*","*load*","*Load*","*Beyond*","*BEYOND*","*B2*","*Atlas*","*Esta*","*Madre*")
$found = @()
foreach ($pat in $patterns) {
    $dirs = Get-ChildItem -Path $Root -Directory -Filter $pat -Recurse -Depth 5 -Force -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        $c = (Get-ChildItem -Path $dir.FullName -Filter *.md -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        $found += "$($dir.FullName) | $c .md | LinkType: $($dir.LinkType) Target: $($dir.Target)"
    }
}
$found = $found | Sort-Object -Unique
if ($found) {
    foreach ($f in $found) { 
        $report += $f
        Write-Host "🔎 $f" -ForegroundColor Cyan
    }
} else {
    $report += "No se encontraron carpetas con patron bodega/load/Beyond/B2/Atlas/Esta en 5 niveles"
    Write-Host "No se encontraron carpetas con esos patrones" -ForegroundColor Yellow
}
$report += ""

# 5. Top 10 carpetas con mas .md (ahi suele estar la bodega escondida)
$report += "--- 5. TOP 10 CARPETAS CON MAS .md (Candidatas a bodega) ---"
$allDirs = Get-ChildItem -Path $Root -Directory -Recurse -Depth 4 -Force -ErrorAction SilentlyContinue
$counts = @()
foreach ($d in $allDirs) {
    try {
        $c = (Get-ChildItem -Path $d.FullName -Filter *.md -File -Recurse -Depth 1 -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($c -gt 20) { $counts += [PSCustomObject]@{ Path=$d.FullName; Count=$c } }
    } catch {}
}
$counts | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    $report += "$($_.Count) .md -> $($_.Path)"
    Write-Host "$($_.Count) .md -> $($_.Path)" -ForegroundColor White
}
$report += ""

# Guardar reporte
$report | Out-File -FilePath $ReportPath -Encoding UTF8
Write-Host ""
Write-Host "✅ Reporte guardado en: $ReportPath" -ForegroundColor Green
Write-Host "Pega el contenido de ese .txt aqui para validacion" -ForegroundColor Yellow

# Mostrar contenido final
Get-Content $ReportPath | Write-Host
