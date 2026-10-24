<#
.SYNOPSIS
    Auditoria completa del proyecto scannerpro_cyber_visualizer.
.DESCRIPTION
    Lee los 4 archivos, valida JSONs, extrae config MQTT/WebSocket del HTML,
    cruza datos entre archivos y reporta inconsistencias.
#>

$ErrorActionPreference = "Continue"
$proj = "C:\RUNEFORGE_V2_CORE\firmware\scannerpro_cyber_visualizer"

function Sep($titulo) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
    Write-Host "  $titulo" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor DarkCyan
}

# ============================================================
# 0. INVENTARIO
# ============================================================
Sep "0. INVENTARIO DE ARCHIVOS"

if (-not (Test-Path $proj)) {
    Write-Host "[X] No existe $proj" -ForegroundColor Red
    return
}

Get-ChildItem $proj -Recurse -File | ForEach-Object {
    $kb = [math]::Round($_.Length / 1KB, 2)
    Write-Host ("  {0,-45} {1,8} KB   {2}" -f $_.Name, $kb, $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))
}

# ============================================================
# 1. JSON: ESP32-PROJECT.json
# ============================================================
Sep "1. ESP32-PROJECT.json"

$j1 = Join-Path $proj "ESP32-PROJECT.json"
$o1 = $null
if (Test-Path $j1) {
    try {
        $o1 = Get-Content $j1 -Raw | ConvertFrom-Json
        Write-Host "[OK] JSON valido" -ForegroundColor Green
        Write-Host ""
        Write-Host "Claves de primer nivel:" -ForegroundColor Yellow
        $o1.PSObject.Properties.Name | ForEach-Object { Write-Host "  - $_" }

        Write-Host ""
        Write-Host "Resumen:"
        if ($o1.proyecto)      { Write-Host "  proyecto: $($o1.proyecto)" }
        if ($o1.version_canon) { Write-Host "  version:  $($o1.version_canon)" }
        if ($o1.fecha_canon)   { Write-Host "  fecha:    $($o1.fecha_canon)" }
        if ($o1.estado_global) { Write-Host "  estado:   $($o1.estado_global)" }

        if ($o1.rutas_canonicas) {
            Write-Host ""
            Write-Host "  Rutas canonicas:" -ForegroundColor Yellow
            $o1.rutas_canonicas.PSObject.Properties | ForEach-Object {
                Write-Host "    $($_.Name) = $($_.Value)"
            }
        }
    } catch {
        Write-Host "[X] JSON INVALIDO: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[X] No existe $j1" -ForegroundColor Red
}

# ============================================================
# 2. JSON: Subsistema ESP32 ScannerPRO.json
# ============================================================
Sep "2. Subsistema ESP32 ScannerPRO.json"

$j2 = Join-Path $proj "Subsistema ESP32 ScannerPRO.json"
$o2 = $null
if (Test-Path $j2) {
    try {
        $o2 = Get-Content $j2 -Raw | ConvertFrom-Json
        Write-Host "[OK] JSON valido" -ForegroundColor Green
        Write-Host ""
        Write-Host "Claves de primer nivel:" -ForegroundColor Yellow
        $o2.PSObject.Properties.Name | ForEach-Object { Write-Host "  - $_" }

        Write-Host ""
        Write-Host "Resumen:"
        foreach ($k in @('proyecto','version','version_canon','fecha','fecha_canon',
                         'estado','estado_global','descripcion','proposito')) {
            if ($o2.$k) { Write-Host "  $k : $($o2.$k)" }
        }
    } catch {
        Write-Host "[X] JSON INVALIDO: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[X] No existe $j2" -ForegroundColor Red
}

# ============================================================
# 3. HTML: scannerpro_cyber_visualizer.html
# ============================================================
Sep "3. scannerpro_cyber_visualizer.html"

$html = Join-Path $proj "scannerpro_cyber_visualizer.html"
$c = $null
if (Test-Path $html) {
    $c = [IO.File]::ReadAllText($html, [System.Text.UTF8Encoding]::new($false))
    $kb = [math]::Round($c.Length / 1KB, 2)
    Write-Host "Tamaño: $kb KB ($($c.Length) bytes)" -ForegroundColor Green

    if ($c.Length -gt 500000) {
        Write-Host "  [!] >500 KB — probablemente ya tiene CDNs embebidos" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Titulo:" -ForegroundColor Yellow
    $title = [regex]::Match($c, '<title>([^<]+)</title>')
    if ($title.Success) { Write-Host "  $($title.Groups[1].Value)" } else { Write-Host "  (sin title)" }

    Write-Host ""
    Write-Host "IPs y URLs detectadas:" -ForegroundColor Yellow
    $ips = [regex]::Matches($c, '\b(?:192\.168\.\d+\.\d+|127\.0\.0\.1|localhost)(?::\d+)?\b') |
        ForEach-Object { $_.Value } | Sort-Object -Unique
    if ($ips) { $ips | ForEach-Object { Write-Host "  $_" } } else { Write-Host "  (ninguna)" }

    Write-Host ""
    Write-Host "Referencias WebSocket / MQTT:" -ForegroundColor Yellow
    $ws = [regex]::Matches($c, 'wss?://[^\s"''<>]+') | ForEach-Object { $_.Value } | Sort-Object -Unique
    if ($ws) { $ws | ForEach-Object { Write-Host "  WS: $_" } }
    $mqtt = [regex]::Matches($c, 'mqtt[s]?://[^\s"''<>]+') | ForEach-Object { $_.Value } | Sort-Object -Unique
    if ($mqtt) { $mqtt | ForEach-Object { Write-Host "  MQTT: $_" } }

    Write-Host ""
    Write-Host "Topics MQTT referenciados (prefix scannerpro/runeforge/collab):" -ForegroundColor Yellow
    $topics = [regex]::Matches($c, "['""]((?:scannerpro|runeforge|collab)[a-z0-9_\-/]*)['""]") |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    if ($topics) { $topics | ForEach-Object { Write-Host "  $_" } }
    else         { Write-Host "  (ninguno detectado con ese prefijo)" }

    Write-Host ""
    Write-Host "Dependencias externas (CDN):" -ForegroundColor Yellow
    $cdn = [regex]::Matches($c, '(?:src|href)=["''](https?://[^"'']+)["'']') |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    if ($cdn) { $cdn | ForEach-Object { Write-Host "  $_" } }
    else      { Write-Host "  (ninguna - offline OK)" -ForegroundColor Green }

    Write-Host ""
    Write-Host "Datos DEMO detectados (MACs falsas):" -ForegroundColor Yellow
    $demoMacs = @('DEADBEEF','COFFEE12','BEEFBABE','11223344','AABBCDCD',
                  '00:11:22:33:44:55','AA:BB:CC:DD:EE:FF','00:00:00:00:00:00')
    $foundDemo = @()
    foreach ($m in $demoMacs) {
        if ($c -match [regex]::Escape($m)) { $foundDemo += $m }
    }
    if ($foundDemo) { $foundDemo | ForEach-Object { Write-Host "  [!] $_" -ForegroundColor Yellow } }
    else            { Write-Host "  (ninguno - sin datos demo hardcoded)" -ForegroundColor Green }

    Write-Host ""
    Write-Host "Boton / funcion SCAN LIVE:" -ForegroundColor Yellow
    if ($c -match 'SCAN\s*LIVE|scan-live|scanLive') {
        Write-Host "  [!] Presente" -ForegroundColor Green
    } else {
        Write-Host "  (no detectado)"
    }

    Write-Host ""
    Write-Host "Librerias JS embebidas (primeras 10):" -ForegroundColor Yellow
    $libs = [regex]::Matches($c, 'class\s+(\w+)|function\s+(\w+)\s*\(') |
        ForEach-Object { if ($_.Groups[1].Value) { $_.Groups[1].Value } else { $_.Groups[2].Value } } |
        Select-Object -Unique -First 10
    if ($libs) { $libs | ForEach-Object { Write-Host "  $_" } }

} else {
    Write-Host "[X] No existe $html" -ForegroundColor Red
}

# ============================================================
# 4. Markdown: powershell_creation_script.md
# ============================================================
Sep "4. powershell_creation_script.md"

$md = Join-Path $proj "powershell_creation_script.md"
if (Test-Path $md) {
    $mc = Get-Content $md -Raw
    Write-Host "Tamaño: $([math]::Round($mc.Length/1KB,2)) KB"
    Write-Host ""
    Write-Host "Primeras 20 lineas:" -ForegroundColor Yellow
    $mc -split "`r?`n" | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }

    Write-Host ""
    Write-Host "Chequeos de calidad:" -ForegroundColor Yellow
    $issues = @()
    if ($mc -match 'cargo\s+check\s+-p\s+\$Name')               { $issues += "cargo check -p requiere workspace raiz" }
    if ($mc -match 'Set-Content.*-Encoding\s+UTF8')             { $issues += "Set-Content -Encoding UTF8 agrega BOM" }
    if ($mc -notmatch 'Test-Path.*_template')                   { $issues += "No valida existencia de _template" }
    if ($mc -notmatch '^\s*param\s*\(')                         { $issues += "Sin bloque param()" }
    if ($issues.Count -eq 0) {
        Write-Host "  [OK] Sin issues detectados" -ForegroundColor Green
    } else {
        $issues | ForEach-Object { Write-Host "  [!] $_" -ForegroundColor Yellow }
    }
} else {
    Write-Host "[X] No existe $md" -ForegroundColor Red
}

# ============================================================
# 5. CRUCE DE DATOS
# ============================================================
Sep "5. CRUCE DE DATOS ENTRE ARCHIVOS"

$issues = @()

if ($o1 -and $o2) {
    # MQTT broker
    $mqtt1 = $o1.esp32.mqtt_broker
    $mqtt2 = $o2.esp32.mqtt_broker
    if ($mqtt1 -and $mqtt2 -and $mqtt1 -ne $mqtt2) {
        $issues += "IP MQTT inconsistente: '$mqtt1' vs '$mqtt2'"
    } elseif ($mqtt1) {
        Write-Host "  [OK] IP MQTT: $mqtt1" -ForegroundColor Green
    }

    # MAC
    $mac1 = $o1.esp32.mac
    $mac2 = $o2.esp32.mac
    if ($mac1 -and $mac2 -and $mac1 -ne $mac2) {
        $issues += "MAC ESP32 inconsistente: '$mac1' vs '$mac2'"
    } elseif ($mac1) {
        Write-Host "  [OK] MAC ESP32: $mac1" -ForegroundColor Green
    }
}

if ($c) {
    if ($c -match '192\.168\.100\.5\b') {
        $issues += "HTML aun referencia IP vieja .5 (deberia ser .10)"
    }
    if ($c -match '192\.168\.100\.10') {
        Write-Host "  [OK] HTML apunta a broker .10" -ForegroundColor Green
    } else {
        $issues += "HTML no referencia 192.168.100.10"
    }
}

Write-Host ""
if ($issues.Count -eq 0) {
    Write-Host "=== SIN INCONSISTENCIAS ===" -ForegroundColor Green
} else {
    Write-Host "=== INCONSISTENCIAS ===" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host "  [!] $_" -ForegroundColor Yellow }
}

# ============================================================
# 6. RESUMEN
# ============================================================
Sep "6. RESUMEN FINAL"

$fileCount = (Get-ChildItem $proj -File -EA SilentlyContinue).Count
Write-Host "Ruta:      $proj"
Write-Host "Archivos:  $fileCount"
Write-Host ""

if ($o1 -and $o2) {
    $k1 = $o1.PSObject.Properties.Name
    $k2 = $o2.PSObject.Properties.Name
    $solo1 = $k1 | Where-Object { $_ -notin $k2 }
    $solo2 = $k2 | Where-Object { $_ -notin $k1 }
    Write-Host "JSONs:" -ForegroundColor Cyan
    Write-Host "  ESP32-PROJECT.json:                $($k1.Count) claves"
    Write-Host "  Subsistema ESP32 ScannerPRO.json:  $($k2.Count) claves"
    Write-Host "  Claves solo en 1:                  $($solo1.Count)"
    Write-Host "  Claves solo en 2:                  $($solo2.Count)"
}