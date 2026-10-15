# =====================================================================
# RUNEFORGE_MERGE_MAIN.ps1
# Fusiona origin/main dentro de recovery/v2.9.1-limpio para crear
# ancestro comun y permitir Pull Request en GitHub.
#
# Estrategia: -X ours  -> en conflictos gana recovery
#             --allow-unrelated-histories  -> permite historias sin comun
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
$env:GIT_PAGER          = 'cat'
$env:GIT_TERMINAL_PROMPT = '0'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

$REPO_OWNER = 'yhb86dy52f-lang'
$REPO_NAME  = 'runeforge-v2-nucleo'

W "==================================================================="
W " RUNEFORGE · MERGE origin/main · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

# --- 0. Sanity checks ---
W "`n[0] Sanity checks"
$branch = (& git branch --show-current 2>&1)
W "    Rama actual: $branch"
if ($branch -ne 'recovery/v2.9.1-limpio') {
    W "ERROR: rama incorrecta. Debe ser recovery/v2.9.1-limpio"
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

$st = @(& git status --short 2>&1)
$nonSub = $st | Where-Object { $_ -notmatch 'simulador' }
if ($nonSub.Count -gt 0) {
    W "    Working tree con cambios:"
    $nonSub | ForEach-Object { W "    $_" }
    W "ERROR: commitear o stash antes."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}
W "    Working tree OK (solo submodulo modificado)"

# --- 1. Backup tag ---
W "`n[1] Creando tag de respaldo"
$backupTag = "backup-antes-merge-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
& git tag $backupTag 2>&1 | Out-Null
W "    Tag: $backupTag -> $(& git rev-parse --short HEAD)"

# --- 2. Fetch origin/main ---
W "`n[2] Fetch origin/main"
& git fetch origin main 2>&1 | ForEach-Object { W "    $_" }

# --- 3. Merge con -X ours ---
W "`n[3] Merge origin/main --allow-unrelated-histories -X ours"
W "    (conflictos se resuelven a favor de recovery)"
$mergeOut = & git merge origin/main --allow-unrelated-histories --no-edit -X ours 2>&1
$mergeOut | ForEach-Object { W "    $_" }

$mergeExit = $LASTEXITCODE

# --- 4. Revisar estado del merge ---
W "`n[4] Estado post-merge"
$st2 = @(& git status --short 2>&1)
$conflicts = @($st2 | Where-Object { $_ -match '^(UU|AA|DD|AU|UA|DU|UD)' })
W "    Lineas status: $($st2.Count)"
W "    Conflictos sin resolver: $($conflicts.Count)"
if ($conflicts.Count -gt 0) {
    $conflicts | Select-Object -First 20 | ForEach-Object { W "    $_" }
}

# Si hay conflictos sin resolver, abortar
if ($conflicts.Count -gt 0) {
    W "`n    [!] Conflictos sin resolver. Abortando merge."
    & git merge --abort 2>&1 | Out-Null
    W "    Merge abortado. Repo en estado previo."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 5. ¿Merge quedó pendiente de commit? ---
$merging = Test-Path ".git\MERGE_HEAD"
if ($merging) {
    W "`n[5] Merge pendiente. Creando commit del merge..."
    $msg = "merge: unificar origin/main (v2.7.0 + Jekyll) con recovery/v2.9.1-limpio"
    & git commit -m $msg 2>&1 | ForEach-Object { W "    $_" }
} else {
    W "`n[5] Merge ya commiteado por git."
}

# --- 6. Verificar resultado ---
W "`n[6] Log post-merge"
& git log --oneline -6 2>&1 | ForEach-Object { W "    $_" }

W "`n[7] Ancestro comun verificado:"
$common = (& git merge-base HEAD origin/main 2>&1)
W "    merge-base: $common"
if ($common) { W "    OK - hay ancestro comun" }
else { W "    ERROR - sin ancestro comun" }

# --- 7. Verificar Jekyll workflow preservado ---
W "`n[8] Verificando workflow Jekyll de main:"
$jekyll = @(& git ls-files ".github/workflows/" 2>&1)
if ($jekyll.Count -gt 0) {
    $jekyll | ForEach-Object { W "    $_" }
    W "    OK - workflow preservado"
} else {
    W "    (no hay workflows, o no se preservo ninguno)"
}

# --- 8. Push ---
W "`n[9] Push a origin/recovery/v2.9.1-limpio"
$pushOut = & git push origin recovery/v2.9.1-limpio 2>&1
$pushOut | ForEach-Object { W "    $_" }

# --- 9. Verificar ancestro con remoto ---
W "`n[10] Verificando ancestro con remoto"
& git fetch origin main 2>&1 | Out-Null
$remoteCommon = (& git merge-base HEAD origin/main 2>&1)
W "    merge-base con origin/main: $remoteCommon"

# --- 10. Crear PR ---
W "`n[11] Creando Pull Request via API..."
$credIn  = "protocol=https`nhost=github.com`n`n"
$credOut = $credIn | git credential fill 2>$null
$token   = ($credOut | Where-Object { $_ -match '^password=' }) -replace '^password=', ''

if (-not $token) {
    W "    ERROR: sin token. Corre git credential fill manualmente."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

$headers = @{
    'Authorization' = "token $token"
    'Accept'        = 'application/vnd.github+json'
    'User-Agent'    = 'Runeforge-PR-Creator'
}

$prBody = @"
## Resumen

Recuperacion completa del repositorio local: reescritura de historial,
limpieza de refs, .gitignore v2.2, reduccion de 2 GB a 877 MB.

Este PR incluye un merge con `origin/main` para establecer ancestro comun.

## Cambios

- Restaurados `README.md` y `MANIFIESTO.md`
- `.gitignore` v2.2 con reglas robustas
- Limpieza de 332 `desktop.ini` dentro de `.git/`
- Removidos blobs >50 MB del historial (instaladores + artefactos Rust)
- `size-pack`: 2,050 MB -> 877 MB

## Verificacion

- `git fsck`: 0 bad sha1, 0 broken refs
- Tags `v2.9.0-LIMPIO` y `v2.9.1-LIMPIO-2`
- Bundle respaldo: `rf-PRE-filerepo-*.bundle` (2.3 GB)
"@

$prPayload = @{
    title = "Recovery v2.9.1-LIMPIO: refs, .gitignore v2.2, repo 2GB -> 877MB"
    head  = "recovery/v2.9.1-limpio"
    base  = "main"
    body  = $prBody
    draft = $false
} | ConvertTo-Json -Depth 5

try {
    $pr = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls" `
        -Headers $headers -Method Post -Body $prPayload `
        -ContentType 'application/json; charset=utf-8' -TimeoutSec 60

    W "    PR #$($pr.number) creado."
    W "    URL: $($pr.html_url)"
} catch {
    W "    ERROR: $($_.Exception.Message)"
    if ($_.ErrorDetails.Message) { W $_.ErrorDetails.Message }
}

# --- 11. Resumen ---
W "`n==================================================================="
W " FIN"
W "==================================================================="
if ($pr) {
    W " Pull Request: $($pr.html_url)"
}

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."