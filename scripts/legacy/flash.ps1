# RUNEFORGE - flash ESP32 en download-mode manual (placas sin auto-reset)
# Auto-ejecutable. Salida al portapapeles. Universal. Sin efectos secundarios.
$ErrorActionPreference = 'Continue'
$log = New-Object System.Collections.Generic.List[string]
function W { param($m) $log.Add([string]$m); Write-Host $m }
function WR { param($m) $log.Add([string]$m); Write-Host $m -NoNewline }

# ------------------------------------------------------------------
# 1) Localizar firmware (universal: sube desde PSScriptRoot)
# ------------------------------------------------------------------
$firm = $null
$cur = $PSScriptRoot
if (-not $cur) { $cur = (Get-Location).Path }
$cands = @()
for ($i = 0; $i -lt 6; $i++) {
    if (-not $cur) { break }
    $cands += $cur
    $p = Split-Path $cur -Parent
    if ($p -eq $cur) { break }
    $cur = $p
}
foreach ($b in $cands) {
    foreach ($sub in @(
        'firmware\RUNEFORGE_COLLAB_FINAL_CORREGIDO_v1\firmware',
        'RUNEFORGE_COLLAB_FINAL_CORREGIDO_v1\firmware',
        'firmware'
    )) {
        $p = Join-Path $b $sub
        if (Test-Path -LiteralPath (Join-Path $p 'ScannerPRO_v9_COLLAB.ino')) {
            $firm = $p; break
        }
    }
    if ($firm) { break }
}
if (-not $firm) { W '[ROJO] no encontre carpeta firmware'; Set-Clipboard ($log -join "`r`n"); return }
W ("[1] firmware: {0}" -f $firm)

# ------------------------------------------------------------------
# 2) arduino-cli
# ------------------------------------------------------------------
$cli = $null
foreach ($c in @(
    (Join-Path $env:ProgramFiles 'Arduino CLI\arduino-cli.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Arduino CLI\arduino-cli.exe')
)) {
    if ($c -and (Test-Path -LiteralPath $c)) { $cli = $c; break }
}
if (-not $cli) {
    $g = Get-Command arduino-cli -ErrorAction SilentlyContinue
    if ($g) { $cli = $g.Source }
}
if (-not $cli) { W '[ROJO] arduino-cli no disponible'; Set-Clipboard ($log -join "`r`n"); return }
W ("[2] arduino-cli: {0}" -f $cli)

# ------------------------------------------------------------------
# 3) COM port
# ------------------------------------------------------------------
$com = $null
foreach ($port in [System.IO.Ports.SerialPort]::GetPortNames()) {
    try {
        $pnp = Get-CimInstance Win32_PnPEntity -Filter "Name LIKE '%($port)%'" -ErrorAction Stop
        if ($pnp -and $pnp.Name -match 'CP210|CH34|CH910|FT232|USB Serial|USB-SERIAL|ESP32|Espressif') {
            $com = $port
            W ("[3] {0} -> {1}" -f $port, $pnp.Name)
            break
        }
    } catch {}
}
if (-not $com) { W '[ROJO] ningun ESP32 en COM'; Set-Clipboard ($log -join "`r`n"); return }

# ------------------------------------------------------------------
# 4) Role (auto: scanner offline -> Scanner, online v9 -> Tag)
# ------------------------------------------------------------------
$role = 'Scanner'
try {
    $ping = Invoke-RestMethod 'http://192.168.100.14/api/ping' -TimeoutSec 2 -ErrorAction Stop
    W ("[4] scanner responde: {0}" -f $ping)
    if ($ping -match 'v9\.0|COLLAB') { $role = 'Tag' }
} catch {
    W '[4] scanner offline -> flasheo Scanner'
}
W ("[4] role: {0}" -f $role)

# ------------------------------------------------------------------
# 5) Stage + compile
# ------------------------------------------------------------------
$map = @{ Tag = 'Tag_RUNEFORGE_FINAL_v2'; Scanner = 'ScannerPRO_v9_COLLAB' }
$name = $map[$role]
$stage = Join-Path $env:TEMP ("rf_stage_" + [guid]::NewGuid().ToString('N'))
$sketch = Join-Path $stage $name
New-Item -ItemType Directory -Path $sketch -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $firm "$name.ino") -Destination (Join-Path $sketch "$name.ino") -Force
foreach ($h in @('config.h','index_html.h','settings_html.h')) {
    $src = Join-Path $firm $h
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $sketch $h) -Force
    }
}
$out = Join-Path $stage 'out'
New-Item -ItemType Directory -Path $out -Force | Out-Null

W '[5] compilando...'
$fqbn = 'esp32:esp32:esp32:PartitionScheme=min_spiffs'
$co = & $cli compile --fqbn $fqbn --warnings none --output-dir $out $sketch 2>&1
$co | Where-Object { $_ -match 'Sketch uses|Global variables|error:' } |
    Select-Object -First 4 | ForEach-Object { W ("    " + $_) }
if ($LASTEXITCODE -ne 0) {
    $co | Select-Object -Last 20 | ForEach-Object { W ("    " + $_) }
    W '[ROJO] compilacion fallida'
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    Set-Clipboard ($log -join "`r`n"); return
}
W '[5] compilacion OK'

# ------------------------------------------------------------------
# 6) esptool + boot_app0
# ------------------------------------------------------------------
$espBase = Join-Path $env:LOCALAPPDATA 'Arduino15\packages\esp32\tools\esptool_py'
if (-not (Test-Path -LiteralPath $espBase)) {
    W '[ROJO] falta esptool_py'; Remove-Item $stage -Recurse -Force -EA SilentlyContinue
    Set-Clipboard ($log -join "`r`n"); return
}
$espDir = Get-ChildItem -LiteralPath $espBase -Directory |
    Sort-Object Name -Descending | Select-Object -First 1
$esptool = Join-Path $espDir.FullName 'esptool.exe'
if (-not (Test-Path -LiteralPath $esptool)) {
    W '[ROJO] falta esptool.exe'; Remove-Item $stage -Recurse -Force -EA SilentlyContinue
    Set-Clipboard ($log -join "`r`n"); return
}
W ("[6] esptool: {0}" -f $esptool)

$coreBase = Join-Path $env:LOCALAPPDATA 'Arduino15\packages\esp32\hardware\esp32'
$coreDir = Get-ChildItem -LiteralPath $coreBase -Directory |
    Sort-Object Name -Descending | Select-Object -First 1
$bootApp0 = Join-Path $coreDir.FullName 'tools\partitions\boot_app0.bin'
if (-not (Test-Path -LiteralPath $bootApp0)) {
    W '[ROJO] falta boot_app0.bin'; Remove-Item $stage -Recurse -Force -EA SilentlyContinue
    Set-Clipboard ($log -join "`r`n"); return
}

$bins = Get-ChildItem -LiteralPath $out -File -Filter '*.bin'
$boot  = $bins | Where-Object { $_.Name -match '\.bootloader\.bin$' } | Select-Object -First 1
$parts = $bins | Where-Object { $_.Name -match '\.partitions\.bin$' } | Select-Object -First 1
$fw    = $bins | Where-Object { $_.Name -match '\.ino\.bin$' }        | Select-Object -First 1
if (-not $boot -or -not $parts -or -not $fw) {
    W '[ROJO] faltan bins compilados'
    Remove-Item $stage -Recurse -Force -EA SilentlyContinue
    Set-Clipboard ($log -join "`r`n"); return
}
W ("[6] bins: {0} | {1} | {2}" -f $boot.Name, $parts.Name, $fw.Name)

# ------------------------------------------------------------------
# 7) Instrucciones + countdown + esptool --before no_reset
# ------------------------------------------------------------------
$instr = @'

============================================================
  SECUENCIA MANUAL (tu placa no auto-resetea)
============================================================

  Tienes 12 segundos. Haz esto EN ORDEN:

    1) PRESIONA y MANTEN el boton BOOT
       (etiquetas: BOOT / IO0 / FLASH)

    2) PULSA y SUELTA el boton EN
       (etiquetas: EN / RESET / RST)

    3) Espera 1 segundo, luego SUELTA BOOT

  El chip queda en download mode. esptool sincroniza.

============================================================
'@
Write-Host $instr
$log.Add($instr)

for ($i = 12; $i -ge 1; $i--) {
    WR ("    >>> {0}  <<<  " -f $i)
    Start-Sleep 1
}
Write-Host "    >>> FLASHEANDO <<<"
$log.Add('    >>> FLASHEANDO <<<')

$espArgs = @(
    '--chip','esp32',
    '--port',$com,
    '--baud','115200',
    '--before','no_reset',
    '--after','hard_reset',
    'write_flash','-z',
    '0x1000', $boot.FullName,
    '0x8000', $parts.FullName,
    '0xe000', $bootApp0,
    '0x10000',$fw.FullName
)
$eo = & $esptool @espArgs 2>&1
$eo | ForEach-Object { W ("    " + $_) }
$ok = ($LASTEXITCODE -eq 0)

Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------------
# 8) Resultado
# ------------------------------------------------------------------
W ''
if ($ok) {
    W '[VERDE] FLASH OK - chip reseteado, arrancando firmware.'
    if ($role -eq 'Scanner') {
        W 'Espera 30s y verifica:'
        W '  Invoke-RestMethod http://192.168.100.14/api/ping'
    } else {
        W 'Verifica Serial Monitor 115200:'
        W '  [TAG] epoch=0 eid=23CD879F340D43BB batt=95'
    }
} else {
    W '[ROJO] FLASH FALLO'
    if ($eo -match 'Failed to connect|no serial data|Wrong boot mode') {
        W 'Chip no entro en download mode. Reintenta:'
        W '  1) BOOT presionado firme'
        W '  2) TAP corto EN (100ms)'
        W '  3) Soltar BOOT 1s despues'
    } else {
        W 'Error distinto. Revisa salida arriba.'
    }
}

$text = $log -join "`r`n"
try { Set-Clipboard -Value $text; Write-Host "`n>> Copiado al portapapeles" } catch {}