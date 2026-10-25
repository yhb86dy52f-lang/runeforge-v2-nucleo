$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# REGLA 3: Captura Total
$capture = New-Object System.Collections.ArrayList
function Log { param($msg, $color="Gray") Write-Host $msg -ForegroundColor $color; $null = $capture.Add($msg) }

Log "=== RUNEFORGE GIT SYNC (NEXUS 3.0) ===" "Cyan"
Log "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "DarkGray"
Log ""

Set-Location "C:\RUNEFORGE_V2_CORE"

# Verificar si hay cambios reales
Log "[*] Buscando cambios locales..." "Yellow"
$status = git status --porcelain

if ([string]::IsNullOrWhiteSpace($status)) {
    Log "`n[OK] El repositorio ya está actualizado. No hay nada nuevo que subir." "Green"
    $capture -join "`r`n" | Set-Clipboard
    Log "`n[OK] Reporte copiado al portapapeles (Ctrl+V)." "Cyan"
    return
}

# Git Add y Commit
Log "[*] Preparando archivos..." "Yellow"
git add .

$commitMsg = "Actualización RUNEFORGE - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Log "[*] Haciendo commit: $commitMsg" "Yellow"
$commitResult = git commit -m "$commitMsg" 2>&1
Log $commitResult "DarkGray"

# Push SEGURO (Sin -f)
Log "`n[*] Subiendo a GitHub (Origin/Main)..." "Yellow"
$pushResult = git push origin main 2>&1

if ($LASTEXITCODE -eq 0) {
    Log "`n[OK] Sincronización completada con éxito. Tu ecosistema está a salvo." "Green"
} else {
    Log "`n[X] ERROR al subir a GitHub:" "Red"
    Log $pushResult "DarkRed"
    Log "Si el error es por 'Push Protection', significa que intentaste subir una clave. Revisa tu código." "Yellow"
}

# REGLA 3: Clipboard final
$capture -join "`r`n" | Set-Clipboard
Log "`n[OK] Reporte completo copiado al portapapeles (Ctrl+V)." "Cyan"