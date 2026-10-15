# =====================================================================
# RUNEFORGE_CREATE_PR.ps1
# Crea Pull Request: recovery/v2.9.1-limpio -> main
# Usa el PAT cacheado en Windows Credential Manager (git:https://github.com)
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

$REPO_OWNER = 'yhb86dy52f-lang'
$REPO_NAME  = 'runeforge-v2-nucleo'
$HEAD       = 'recovery/v2.9.1-limpio'
$BASE       = 'main'

W "==================================================================="
W " RUNEFORGE · CREAR PULL REQUEST · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

# --- 1. Recuperar PAT del credential manager ---
W "`n[1] Recuperando token desde git credential fill..."
$credInput = "protocol=https`nhost=github.com`n`n"
$credOut   = $credInput | git credential fill 2>$null
$user = ($credOut | Where-Object { $_ -match '^username=' }) -replace '^username=', ''
$pass = ($credOut | Where-Object { $_ -match '^password=' }) -replace '^password=', ''

if (-not $pass) {
    W "ERROR: no se pudo obtener token. Ejecuta antes: git credential fill"
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}
W "    Usuario: $user"
W "    Token:   $(('*' * [Math]::Min($pass.Length,12)))...($($pass.Length) chars)"

# --- 2. Verificar que el token sirve ---
W "`n[2] Verificando autenticacion contra api.github.com..."
$headers = @{
    'Authorization' = "token $pass"
    'Accept'        = 'application/vnd.github+json'
    'User-Agent'    = 'Runeforge-PR-Creator'
}

try {
    $me = Invoke-RestMethod -Uri 'https://api.github.com/user' -Headers $headers -Method Get -TimeoutSec 30
    W "    Autenticado como: $($me.login)"
} catch {
    W "ERROR autenticando: $_"
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 3. Verificar que la rama head existe ---
W "`n[3] Verificando rama $HEAD en el remoto..."
try {
    $branch = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches/$HEAD" -Headers $headers -Method Get -TimeoutSec 30
    W "    Rama OK. SHA: $($branch.commit.sha.Substring(0,7))"
} catch {
    W "ERROR consultando rama: $_"
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 4. Verificar si ya hay PR abierto ---
W "`n[4] Buscando PRs existentes..."
$existingPrs = @()
try {
    $existingPrs = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls?state=open&head=$REPO_OWNER`:$HEAD" -Headers $headers -Method Get -TimeoutSec 30
} catch {
    W "    (no se pudo consultar, seguimos)"
}

if ($existingPrs.Count -gt 0) {
    $pr = $existingPrs[0]
    W "    Ya existe PR #$($pr.number): $($pr.html_url)"
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}
W "    Sin PR previo. Creando uno nuevo."

# --- 5. Crear el PR ---
W "`n[5] Creando Pull Request..."

$prTitle = "Recovery v2.9.1-LIMPIO: refs, .gitignore v2.2, repo 2GB -> 877MB"

$prBody = @"
## Resumen

Recuperacion completa del repositorio local tras corrupcion de refs y bloat de 2 GB.

## Cambios

- Restaurados ``README.md`` y ``MANIFIESTO.md`` (borrados accidentalmente en commit previo)
- ``.gitignore`` reescrito a v2.2 con reglas robustas (build, venv, modelos, backups, secretos)
- Limpieza de 332 ``desktop.ini`` dentro de ``.git/`` (basura de Google Drive)
- Removidos del historial blobs >50 MB (instaladores + artefactos Rust de ``target/``)
- Reduccion de ``size-pack``: 2,050 MB -> 877 MB

## Verificacion

- ``git fsck``: 0 bad sha1, 0 broken refs
- Tags ``v2.9.0-LIMPIO`` y ``v2.9.1-LIMPIO-2`` creados
- Bundle de respaldo previo a reescritura: ``rf-PRE-filerepo-*.bundle`` (2.3 GB)

## No incluye

- No toca ``main`` remoto directamente
- Sin conflictos resueltos a ciegas - la rama es lineal
"@

$prPayload = @{
    title = $prTitle
    head  = $HEAD
    base  = $BASE
    body  = $prBody
    draft = $false
    maintainer_can_modify = $true
} | ConvertTo-Json -Depth 5

try {
    $pr = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls" `
        -Headers $headers `
        -Method Post `
        -Body $prPayload `
        -ContentType 'application/json; charset=utf-8' `
        -TimeoutSec 60

    W "    PR creado exitosamente."
    W "    Numero: $($pr.number)"
    W "    URL:    $($pr.html_url)"
    W "    Estado: $($pr.state)"
    W "    Mergeable state: $($pr.mergeable_state)"
} catch {
    $errMsg = $_.Exception.Message
    W "ERROR creando PR: $errMsg"
    if ($_.ErrorDetails.Message) {
        W "Detalles:"
        W $_.ErrorDetails.Message
    }
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 6. Consultar conflictos ---
W "`n[6] Consultando estado de mergeabilidad..."
Start-Sleep -Seconds 3
try {
    $prCheck = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/pulls/$($pr.number)" -Headers $headers -Method Get -TimeoutSec 30
    W "    mergeable:       $($prCheck.mergeable)"
    W "    mergeable_state: $($prCheck.mergeable_state)"
    W "    commits:         $($prCheck.commits)"
    W "    changed_files:   $($prCheck.changed_files)"
    W "    additions:       +$($prCheck.additions)"
    W "    deletions:       -$($prCheck.deletions)"

    if ($prCheck.mergeable -eq $false) {
        W "`n    [!] Hay conflictos. Resolver en:"
        W "        https://github.com/$REPO_OWNER/$REPO_NAME/pull/$($pr.number)/conflicts"
    }
} catch {
    W "    (no se pudo consultar mergeabilidad)"
}

# --- 7. Resumen ---
W "`n==================================================================="
W " PR LISTO"
W "==================================================================="
W " URL: https://github.com/$REPO_OWNER/$REPO_NAME/pull/$($pr.number)"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."