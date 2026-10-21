# =====================================================================
# RUNEFORGE_SHOW_AUDIT.ps1
# Lee el último reporte JSON de auditoría HTML y muestra los resultados
# en una tabla formateada (Consola + Portapapeles).
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · VISOR DE AUDITORÍA HTML · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$ReportsDir = "C:\RUNEFORGE_V2_CORE\reports"
$LatestJson = Get-ChildItem -Path $ReportsDir -Filter "html_audit_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $LatestJson) {
    W "[!] No se encontró ningún reporte JSON de auditoría."
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

W "`n[FASE 1] Leyendo reporte: $($LatestJson.Name)"
$data = Get-Content -Path $LatestJson.FullName -Raw | ConvertFrom-Json
$top = $data | Sort-Object MB -Descending | Select-Object -First 15

W "`n[FASE 2] TOP 15 HTML MÁS PESADOS (Candidatos a Refactorización):"
W "----------------------------------------------------------------------------------------------------"
W ("{0,8} | {1,-22} | {2,-35} | {3}" -f "TAMAÑO", "TIPO", "TÍTULO", "RUTA")
W "----------------------------------------------------------------------------------------------------"

foreach ($item in $top) {
    # Acortar título y ruta si son muy largos
    $title = if ($item.Titulo.Length -gt 32) { $item.Titulo.Substring(0, 29) + "..." } else { $item.Titulo }
    $path  = if ($item.Ruta.Length -gt 60) { "..." + $item.Ruta.Substring($item.Ruta.Length - 57) } else { $item.Ruta }
    
    $line = "{0,5} MB | {1,-22} | {2,-35} | {3}" -f $item.MB, $item.Tipo, $title, $path
    W $line
}

W "----------------------------------------------------------------------------------------------------"
W "`n[FASE 3] Distribución por Tipo:"
$data | Group-Object Tipo | ForEach-Object {
    W ("  - {0,-25} : {1} archivos" -f $_.Name, $_.Count)
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Los archivos clasificados como 'SPA / Tauri Frontend' o 'Dashboard'"
W " son los candidatos ideales para optimización."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
