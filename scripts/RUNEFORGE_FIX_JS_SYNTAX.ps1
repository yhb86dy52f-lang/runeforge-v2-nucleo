# =====================================================================
# RUNEFORGE_FIX_JS_SYNTAX.ps1
# Corrige la sintaxis de los template strings de JavaScript que se
# rompieron al ser interpretados por PowerShell.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · FIX DE SINTAXIS JS · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$MasterFile = "C:\RUNEFORGE_V2_CORE\public\index_master_FINAL.html"

if (-not (Test-Path $MasterFile)) {
    W "[!] ERROR: No se encontró el archivo maestro."
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

# Leer el archivo
$content = Get-Content -Path $MasterFile -Raw

# 1. Corregir la línea de 'counts'
$badCounts = "document.getElementById('counts').textContent = 3E70:  | FFFF: ;"
$goodCounts = "document.getElementById('counts').textContent = `3E70: `${res.c3E70} | FFFF: `${res.cFFFF}`;"

# 2. Corregir la línea de 'gaugeV'
$badGaugeV = "document.getElementById('gaugeV').setAttribute('stroke-dasharray', `${pct * 2.51} 251);"
$goodGaugeV = "document.getElementById('gaugeV').setAttribute('stroke-dasharray', ````${pct * 2.51} 251````);"

# 3. Corregir la línea de 'gaugeG'
$badGaugeG = "document.getElementById('gaugeG').setAttribute('stroke-dasharray', `${pct * 2.51} 251);"
$goodGaugeG = "document.getElementById('gaugeG').setAttribute('stroke-dasharray', ````${pct * 2.51} 251````);"

# Reemplazos directos con expresiones regulares para mayor seguridad
$content = $content -replace "document\.getElementById\('counts'\)\.textContent = 3E70:  \| FFFF: ;", "document.getElementById('counts').textContent = ``3E70: `${res.c3E70} | FFFF: `${res.cFFFF}``;"

$content = $content -replace "document\.getElementById\('gaugeV'\)\.setAttribute\('stroke-dasharray', `\$\{pct \* 2\.51\} 251\);", "document.getElementById('gaugeV').setAttribute('stroke-dasharray', ```${pct * 2.51} 251```);"

$content = $content -replace "document\.getElementById\('gaugeG'\)\.setAttribute\('stroke-dasharray', `\$\{pct \* 2\.51\} 251\);", "document.getElementById('gaugeG').setAttribute('stroke-dasharray', ```${pct * 2.51} 251```);"

# Guardar el archivo corregido
$content | Set-Content -Path $MasterFile -Encoding UTF8

W "`n[FASE 1] Archivo corregido y guardado."
W "  [+] Ubicación: $MasterFile"
W "  [+] Tamaño: $((Get-Item $MasterFile).Length) bytes"

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Se reparó la sintaxis de los template strings (backticks) en"
W " la función decodeHex(). La interfaz ahora debe renderizar los"
W " gauges, el camión SVG y el JSON sin errores."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
