# =====================================================================
# RUNEFORGE_PURGE_SECRETS.ps1
# Elimina apps_full.json y public/lab-v5-pro.html del repo Y del historial
# ATENCION: reescribe historia. Requiere revocar secretos ANTES.
# =====================================================================

$ErrorActionPreference   = 'Continue'
$ProgressPreference      = 'SilentlyContinue'
$env:GIT_PAGER           = 'cat'
$env:GIT_TERMINAL_PROMPT = '0'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

$FILTER_REPO = "C:\Users\nesth\AppData\Roaming\Python\Python311\Scripts\git-filter-repo.exe"
$REPO_OWNER  = 'yhb86dy52f-lang'
$REPO_NAME   = 'runeforge-v2-nucleo'

W "==================================================================="
W " RUNEFORGE · PURGE SECRETS · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

Set-Location C:\RUNEFORGE_V2_CORE

# --- 0. Confirmacion explicita ---
W ""
W "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
W " ESTE SCRIPT REESCRIBE EL HISTORIAL Y HACE FORCE PUSH"
W " ANTES DE CONTINUAR, CONFIRMA:"
W ""
W "   [ ] Ya revocaste las Google API Keys"
W "   [ ] Ya revocaste las Azure AD secrets"
W "   [ ] Ya revocaste las Tencent WeChat App IDs"
W "   [ ] Ya eliminaste las service account keys de GCP"
W ""
W "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
W ""
$resp = Read-Host "Escribe 'REVOCADO' para continuar (o cualquier otra cosa para abortar)"
if ($resp -ne 'REVOCADO') {
    W "Abortado por el usuario."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 1. Backup ---
W "`n[1] Backup del repo antes de reescribir"
$bundlePath = "$env:TEMP\rf-PRESECRETS-$(Get-Date -Format 'yyyyMMdd-HHmmss').bundle"
& git bundle create $bundlePath --all 2>&1 | Out-Null
if (Test-Path $bundlePath) {
    $mb = [math]::Round((Get-Item $bundlePath).Length / 1MB, 2)
    W "    OK: $bundlePath ($mb MB)"
} else {
    W "    ERROR: bundle no creado. Abortando."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 2. Identificar archivos con secretos ---
W "`n[2] Archivos objetivo"
$targets = @(
    'apps_full.json',
    'public/lab-v5-pro.html'
)
foreach ($t in $targets) {
    if (Test-Path $t) { W "    EXISTE: $t  ($((Get-Item $t).Length) bytes)" }
    else              { W "    NO EXISTE: $t" }
}

# --- 3. Confirmar con git que estan trackeados ---
W "`n[3] Verificando tracking"
foreach ($t in $targets) {
    $tracked = & git ls-files -- $t 2>&1
    if ($tracked) { W "    TRACKEADO: $t" }
    else          { W "    NO TRACKEADO: $t" }
}

# --- 4. Eliminar del working tree ---
W "`n[4] Borrando archivos del working tree"
foreach ($t in $targets) {
    if (Test-Path $t) {
        Remove-Item $t -Force -ErrorAction SilentlyContinue
        W "    Borrado: $t"
    }
}

# --- 5. Reescribir historial con filter-repo ---
W "`n[5] Reescribiendo historial (puede tardar varios minutos)"
$pathsToRemove = $targets | ForEach-Object { "--path"; $_ }
$args = @('--invert-paths','--force') + $pathsToRemove + @('--refs','refs/heads/main')
W "    Ejecutando: git-filter-repo $($args -join ' ')"
$filterOut = & $FILTER_REPO @args 2>&1
$filterOut | ForEach-Object { W "    $_" }

# --- 6. Verificar que ya no estan ---
W "`n[6] Verificacion post-filter"
$stillThere = & git log --all --full-history --oneline -- $targets 2>&1
if ($stillThere) {
    W "    ADVERTENCIA: aun hay commits que tocan los archivos:"
    $stillThere | Select-Object -First 5 | ForEach-Object { W "    $_" }
} else {
    W "    OK: sin referencias en el historial"
}

# --- 7. Verificar que el archivo no existe ---
W "`n[7] Verificacion de archivos"
foreach ($t in $targets) {
    if (Test-Path $t) { W "    AUN EXISTE: $t" }
    else              { W "    OK borrado: $t" }
}

# --- 8. Estado del repo ---
W "`n[8] Estado actual"
& git log --oneline -3 2>&1 | ForEach-Object { W "    $_" }
W "    size-pack:"
& git count-objects -vH 2>&1 | Where-Object { $_ -match 'size-pack' } | ForEach-Object { W "    $_" }

# --- 9. Re-agregar remote (filter-repo lo quita) ---
W "`n[9] Configurando remote"
$existing = & git remote get-url origin 2>$null
if (-not $existing) {
    W "    Agregando origin..."
    & git remote add origin "https://github.com/$REPO_OWNER/$REPO_NAME.git" 2>&1 | Out-Null
}
& git remote -v 2>&1 | ForEach-Object { W "    $_" }

# --- 10. Force push ---
W "`n[10] Force push a origin/main"
W "    (reescribe la historia remota - es lo correcto aqui)"
& git push origin main --force 2>&1 | ForEach-Object { W "    $_" }

# --- 11. Push de tags ---
W "`n[11] Push de tags"
& git push origin --tags --force 2>&1 | ForEach-Object { W "    $_" }

# --- 12. Resumen ---
W "`n==================================================================="
W " FIN"
W "==================================================================="
W ""
W " PROXIMOS PASOS OBLIGATORIOS:"
W " 1. GitHub Secret Scanning:"
W "    https://github.com/$REPO_OWNER/$REPO_NAME/security/secret-scanning"
W "    Cierra las alertas como 'Revoked'"
W ""
W " 2. Si alguien clono el repo con los secretos, ellos tienen copia."
W "    Solo queda confiar en que revocaste a tiempo."
W ""
W " 3. Regenera los secretos en las consolas oficiales y guardalos"
W "    en variables de entorno o .env local (NO en el repo)."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."