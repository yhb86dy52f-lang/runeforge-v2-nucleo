<#
.SYNOPSIS
    Compara los 2 JSONs del proyecto scannerpro_cyber_visualizer.
#>
$ErrorActionPreference = "Continue"
$dir = "C:\RUNEFORGE_V2_CORE\firmware\scannerpro_cyber_visualizer"

$j1 = Join-Path $dir "ESP32-PROJECT.json"
$j2 = Join-Path $dir "Subsistema ESP32 ScannerPRO.json"

if (-not (Test-Path $j1)) { throw "[X] No existe $j1" }
if (-not (Test-Path $j2)) { throw "[X] No existe $j2" }

Write-Host ""
Write-Host "=== 1. Claves de primer nivel ===" -ForegroundColor Cyan

$o1 = Get-Content $j1 -Raw | ConvertFrom-Json
$o2 = Get-Content $j2 -Raw | ConvertFrom-Json

$k1 = $o1.PSObject.Properties.Name
$k2 = $o2.PSObject.Properties.Name

Write-Host ""
Write-Host "ESP32-PROJECT.json ($($k1.Count) claves):"
$k1 | ForEach-Object { Write-Host "  - $_" }
Write-Host ""
Write-Host "Subsistema ESP32 ScannerPRO.json ($($k2.Count) claves):"
$k2 | ForEach-Object { Write-Host "  - $_" }

Write-Host ""
Write-Host "=== 2. Claves unicas vs compartidas ===" -ForegroundColor Cyan
$solo1 = $k1 | Where-Object { $_ -notin $k2 }
$solo2 = $k2 | Where-Object { $_ -notin $k1 }
$compartidas = $k1 | Where-Object { $_ -in $k2 }

if ($solo1) { Write-Host "Solo en ESP32-PROJECT.json:" -ForegroundColor Yellow; $solo1 | ForEach-Object { Write-Host "  + $_" } }
if ($solo2) { Write-Host "Solo en Subsistema JSON:" -ForegroundColor Yellow; $solo2 | ForEach-Object { Write-Host "  + $_" } }
if ($compartidas) { Write-Host "Compartidas ($($compartidas.Count)):" -ForegroundColor Green; $compartidas | ForEach-Object { Write-Host "  = $_" } }

Write-Host ""
Write-Host "=== 3. Diff de valores en claves compartidas ===" -ForegroundColor Cyan
foreach ($k in $compartidas) {
    $v1 = $o1.$k | ConvertTo-Json -Compress -Depth 10
    $v2 = $o2.$k | ConvertTo-Json -Compress -Depth 10
    if ($v1 -ne $v2) {
        Write-Host "  [!] $k DIFIERE" -ForegroundColor Yellow
        Write-Host "      v1: $($v1.Substring(0, [Math]::Min(120, $v1.Length)))..."
        Write-Host "      v2: $($v2.Substring(0, [Math]::Min(120, $v2.Length)))..."
    } else {
        Write-Host "  [ok] $k iguales" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== 4. Recomendacion ===" -ForegroundColor Cyan
if ($solo2.Count -eq 0 -and $solo1.Count -eq 0) {
    Write-Host "  -> Duplicados exactos (mismo contenido). Elimina uno."
} elseif ($solo2.Count -gt 0 -and $solo1.Count -gt 0) {
    Write-Host "  -> Tienen info distinta. Fusionar en uno solo o mantener ambos con propositos claros."
} else {
    Write-Host "  -> Uno contiene al otro + extras. El mas completo es:"
    if ($solo1.Count -gt 0) { Write-Host "     ESP32-PROJECT.json" }
    if ($solo2.Count -gt 0) { Write-Host "     Subsistema ESP32 ScannerPRO.json" }
}