# =====================================================================
# RUNEFORGE_MERGE_V2.ps1
# Fusiona origin/main (shallow fetch) dentro de recovery/v2.9.1-limpio
# para crear ancestro comun y permitir Pull Request.
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
W " RUNEFORGE · MERGE V2 · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

# --- 0. Sanity checks ---
W "`n[0] Sanity checks"
$branch = (& git branch --show-current 2>&1)
W "    Rama actual: $branch"
if ($branch -ne 'recovery/v2.9.1-limpio') {
    W "ERROR: rama incorrecta."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

$st = @(& git status --short 2>&1)
$nonSub = @($st | Where-Object { $_ -notmatch 'simulador' })
if ($nonSub.Count -gt 0) {
    W "ERROR: working tree con cambios:"
    $nonSub | ForEach-Object { W "    $_" }
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}
W "    OK"

# --- 1. Verificar que no hay merge en progreso ---
if (Test-Path ".git\MERGE_HEAD") {
    W "`n[1] Detectado merge anterior sin terminar. Abortando..."
    & git merge --abort 2>&1 | Out-Null
}
W "`n[1] Sin merge pendiente"

# --- 2. Backup tag ---
$backupTag = "backup-v2-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
& git tag $backupTag 2>&1 | Out-Null
W "`n[2] Tag backup: $backupTag"

# --- 3. Fetch con 3 estrategias ---
W "`n[3] Fetch origin/main (3 intentos)"

$fetchOk = $false

# Intento A: shallow fetch (barato)
W "    [A] git fetch --depth=1 origin main"
$out = & git fetch --depth=1 origin main 2>&1
$out | ForEach-Object { W "        $_" }
if ($LASTEXITCODE -eq 0) { $fetchOk = $true; W "        OK" }
else { W "        FALLO" }

# Intento B: fetch normal si A falló
if (-not $fetchOk) {
    W "    [B] git fetch origin main (normal)"
    $out = & git fetch origin main 2>&1
    $out | ForEach-Object { W "        $_" }
    if ($LASTEXITCODE -eq 0) { $fetchOk = $true; W "        OK" }
    else { W "        FALLO" }
}

# Intento C: fetch --unshallow si B falló
if (-not $fetchOk) {
    W "    [C] git fetch --unshallow origin main"
    $out = & git fetch --unshallow origin main 2>&1
    $out | ForEach-Object { W "        $_" }
    if ($LASTEXITCODE -eq 0) { $fetchOk = $true; W "        OK" }
    else { W "        FALLO" }
}

if (-not $fetchOk) {
    W "`nERROR: los 3 fetch fallaron. Sin origin/main no se puede mergear."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 4. VALIDAR que origin/main existe y es un hash ---
W "`n[4] Validando origin/main"
$originMainSha = (& git rev-parse --verify origin/main 2>&1)
if ($originMainSha -match '^[a-f0-9]{40}$') {
    W "    OK. origin/main = $($originMainSha.Substring(0,7))"
} else {
    W "    ERROR: origin/main no es un hash valido: $originMainSha"
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 5. Merge ---
W "`n[5] Merge origin/main --allow-unrelated-histories -X ours"
$mergeOut = & git merge origin/main --allow-unrelated-histories --no-edit -X ours 2>&1
$mergeOut | ForEach-Object { W "    $_" }

# --- 6. Verificar conflictos ---
W "`n[6] Verificando conflictos"
$st2 = @(& git status --short 2>&1)
$conflicts = @($st2 | Where-Object { $_ -match '^(UU|AA|DD|AU|UA|DU|UD)' })
W "    Conflictos sin resolver: $($conflicts.Count)"

if ($conflicts.Count -gt 0) {
    $conflicts | Select-Object -First 10 | ForEach-Object { W "    $_" }
    W "`n    Abortando merge..."
    & git merge --abort 2>&1 | Out-Null
    W "    Repo restaurado."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 7. Verificar MERGE_HEAD y commitear ---
if (Test-Path ".git\MERGE_HEAD") {
    W "`n[7] Commiteando merge..."
    & git commit --no-edit 2>&1 | ForEach-Object { W "    $_" }
} else {
    W "`n[7] Merge ya commiteado (fast-forward o auto)"
}

# --- 8. VALIDAR merge-base ---
W "`n[8] Validando ancestro comun"
$mergeBase = (& git merge-base HEAD origin/main 2>&1)
if ($mergeBase -match '^[a-f0-9]{40}$') {
    W "    OK. merge-base = $($mergeBase.Substring(0,7))"
} else {
    W "    ERROR: no hay ancestro comun. Salida: $mergeBase"
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 9. Log ---
W "`n[9] Log post-merge"
& git log --oneline -6 2>&1 | ForEach-Object { W "    $_" }

# --- 10. Push ---
W "`n[10] Push a origin/recovery/v2.9.1-limpio"
$pushOut = & git push origin recovery/v2.9.1-limpio 2>&1
$pushOut | ForEach-Object { W "    $_" }

# --- 11. Re-fetch para validar ancestro con remoto ---
W "`n[11] Re-validando ancestro contra remoto"
& git fetch --depth=1 origin main 2>&1 | Out-Null
$remoteBase = (& git merge-base HEAD origin/main 2>&1)
if ($remoteBase -match '^[a-f0-9]{40}$') {
    W "    OK. Ancestro con origin/main confirmado."
} else {
    W "    ADVERTENCIA: ancestro remoto no confirmado: $remoteBase"
}

# --- 12. Crear PR ---
W "`n[12] Creando Pull Request via API"
$credIn  = "protocol=https`nhost=github.com`n`n"
$credOut = $credIn | git credential fill 2>$null
$token   = ($credOut | Where-Object { $_ -match '^password=' }) -replace '^password=', ''

if (-not $token) {
    W "    ERROR: sin token."
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
- Removidos blobs >50 MB del historial
- `size-pack`: 2,050 MB -> 877 MB

## Verificacion

- `git fsck`: 0 bad sha1, 0 broken refs
- Tags `v2.9.0-LIMPIO` y `v2.9.1-LIMPIO-2`
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

# --- 13. Resumen ---
W "`n==================================================================="
W " FIN"
W "==================================================================="
if ($pr) { W " PR: $($pr.html_url)" }

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."