# =====================================================================
# RUNEFORGE_VALIDATE_MASTER_28K.ps1
# Valida que el index_master_FINAL.html contenga los IDs críticos
# (radarCanvas, fuelGaugeCircle, etc.) y la regla @media print.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · VALIDACIÓN DEL MASTER 28KB · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$MasterFile = "C:\RUNEFORGE_V2_CORE\public\index_master_FINAL.html"

if (-not (Test-Path $MasterFile)) {
    W "[!] ERROR CRÍTICO: No se encontró $MasterFile"
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

$content = Get-Content -Path $MasterFile -Raw
$sizeKB = [math]::Round((Get-Item $MasterFile).Length / 1KB, 2)
W "[OK] Archivo encontrado: $MasterFile ($sizeKB KB)"

# 1. Validar IDs Críticos
W "`n[FASE 1] Auditando IDs críticos del DOM..."
$criticalIds = @(
    "radarCanvas",
    "fuelGaugeCircle",
    "deviceTableBody",
    "mqttStatusBadge"
)

$missingIds = @()
foreach ($id in $criticalIds) {
    # Busca id="nombre" o id='nombre' o id=nombre
    if ($content -match "id=['`"]$id['`"]") {
        W "  [+] ID encontrado: $id"
    } else {
        W "  [!] ID FALTANTE: $id"
        $missingIds += $id
    }
}

# 2. Validar Regla de Impresión (@media print)
W "`n[FASE 2] Auditando estilos de impresión (Etiqueta QR)..."
if ($content -match '@media\s+print') {
    W "  [+] Regla '@media print' detectada. La etiqueta es imprimible."
} else {
    W "  [!] ALERTA: No se encontró la regla '@media print'. La etiqueta no se imprimirá correctamente."
}

# 3. Validar Estructura de Tabs (Pestañas)
W "`n[FASE 3] Auditando estructura de Tabs..."
if ($content -match 'class=["''].*tab.*["'']') {
    W "  [+] Estructura de pestañas (Tabs) detectada en el CSS/HTML."
} else {
    W "  [!] No se detectaron clases de pestañas. Verifica el CSS."
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
if ($missingIds.Count -eq 0 -and $content -match '@media\s+print') {
    W " ESTADO: MASTER FINAL LISTO Y VALIDADO PARA APP TABAJO."
} else {
    W " ESTADO: REQUIERE ATENCIÓN. Revisa los IDs faltantes o el CSS."
}
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
