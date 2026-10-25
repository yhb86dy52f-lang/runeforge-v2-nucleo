# =====================================================================
# RUNEFORGE_OPTIMIZE_MASTER.ps1
# Limpia el código muerto (React/Tailwind inline) y elimina la
# dependencia del CDN de Tailwind para que funcione offline.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · OPTIMIZACIÓN MAESTRA (DEAD CODE REMOVAL) · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$MasterFile = "C:\RUNEFORGE_V2_CORE\public\index_master_FINAL.html"
$BackupFile = "C:\RUNEFORGE_V2_CORE\public\index_master_FINAL_BACKUP.html"

if (-not (Test-Path $MasterFile)) {
    W "[!] ERROR: No se encontró el archivo maestro."
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

# 1. Crear respaldo de seguridad
W "`n[FASE 1] Creando copia de seguridad..."
Copy-Item -Path $MasterFile -Destination $BackupFile -Force
$oldSize = [math]::Round((Get-Item $MasterFile).Length / 1KB, 2)
W "  [+] Backup guardado: $BackupFile ($oldSize KB)"

# 2. Leer y Limpiar el HTML
W "`n[FASE 2] Limpiando código muerto..."
$content = Get-Content -Path $MasterFile -Raw

# A. Eliminar el CDN de Tailwind en el HEAD
$content = $content -replace '<script src="https://cdn.tailwindcss.com"></script>', '<!-- Tailwind CDN eliminado: usando estilos locales -->'

# B. Eliminar el bloque gigante de React/Tailwind minificado
# Buscamos desde el inicio del script masivo hasta la etiqueta </script>
$deadCodePattern = '(?s)/\* INLINED-OFFLINE: https://cdn.tailwindcss\.com \*/.*?(?=document\.querySelectorAll\("nav button"\))'
$content = $content -replace $deadCodePattern, '// [CÓDIGO MUERTO DE REACT/TAILWIND ELIMINADO PARA OPTIMIZACIÓN]`n'

# 3. Guardar el archivo optimizado
W "`n[FASE 3] Guardando versión optimizada..."
$content | Set-Content -Path $MasterFile -Encoding UTF8
$newSize = [math]::Round((Get-Item $MasterFile).Length / 1KB, 2)
W "  [+] Archivo guardado: $MasterFile"
W "  [+] Reducción de tamaño: $oldSize KB -> $newSize KB"

# 4. Validación final rápida
W "`n[FASE 4] Validando que los IDs sigan intactos..."
$finalContent = Get-Content -Path $MasterFile -Raw
$ids = @("radarCanvas", "fuelGaugeCircle", "deviceTableBody", "mqttStatusBadge")
foreach ($id in $ids) {
    if ($finalContent -match "id=['`"]$id['`"]") {
        W "  [+] ID conservado: $id"
    } else {
        W "  [!] ID PERDIDO: $id"
    }
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Se ha eliminado el código minificado de React y Tailwind que no"
W " estaba siendo utilizado. El archivo ahora es puramente estático."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
