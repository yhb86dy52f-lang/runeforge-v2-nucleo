# =====================================================================
# RUNEFORGE_FINAL_CLEANUP.ps1
# v2.9.1-LIMPIO-2
#
# Hace en orden:
#   1. Borra los 256 desktop.ini dentro de .git/ (basura de Google Drive)
#   2. Verifica con git fsck
#   3. Stage + commit + tag
#   4. Configura remoto origin -> GitHub
#   5. Push a origin/main + tags
#   6. Bundle de respaldo en %TEMP%
#
# Requisitos:
#   - Ejecutar desde C:\RUNEFORGE_V2_CORE
#   - Git instalado (2.44.0 o superior)
#   - Credenciales GitHub configuradas (PAT o gh auth login)
# =====================================================================

$REMOTE_URL = "https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git"

$ErrorActionPreference  = 'Continue'
$ProgressPreference     = 'SilentlyContinue'
$env:GIT_PAGER          = 'cat'
$env:GIT_TERMINAL_PROMPT = '0'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · FINAL CLEANUP · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W " PWD: $(Get-Location)"
W "==================================================================="

# ---------------------------------------------------------------- 0
if (-not (Test-Path ".git")) {
    W "ERROR: no hay .git aqui. Abortando."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}
if ((& git rev-parse --is-inside-work-tree 2>&1) -ne 'true') {
    W "ERROR: no es working tree git."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# ---------------------------------------------------------------- 1
W "`n[1] Borrando desktop.ini dentro de .git/ ..."
$targets = Get-ChildItem -Path ".git" -Recurse -File -Force -Filter "desktop.ini" -ErrorAction SilentlyContinue
W "    Encontrados: $($targets.Count)"
$borrados = 0
foreach ($f in $targets) {
    try {
        Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
        $borrados++
    } catch {
        W "    No se pudo borrar: $($f.FullName)"
    }
}
W "    Borrados: $borrados"

# ---------------------------------------------------------------- 2
W "`n[2] git fsck --full (resumen):"
$fsck = @(& git fsck --full 2>&1)
$bad      = ($fsck | Where-Object { $_ -match 'bad sha1' }).Count
$dangling = ($fsck | Where-Object { $_ -match 'dangling' }).Count
$errs     = ($fsck | Where-Object { $_ -match 'error' }).Count
W "    bad sha1:  $bad"
W "    dangling:  $dangling  (normal)"
W "    errors:    $errs"
if ($bad -gt 0) {
    W "    Primeros 5 bad sha1:"
    $fsck | Where-Object { $_ -match 'bad sha1' } | Select-Object -First 5 | ForEach-Object { W "      $_" }
}

# ---------------------------------------------------------------- 3
W "`n[3] Working tree antes de commit:"
$st = @(& git status --short 2>&1)
W "    Lineas: $($st.Count)"
$st | Select-Object -First 20 | ForEach-Object { W "    $_" }

# ---------------------------------------------------------------- 4
W "`n[4] git add -A"
& git add -A 2>&1 | Out-Null

# ---------------------------------------------------------------- 5
W "`n[5] Commit:"
$staged = @(& git diff --cached --name-only 2>&1)
if ($staged.Count -eq 0) {
    W "    Nada staged. No se commitea."
} else {
    W "    Archivos staged: $($staged.Count)"
    $msg = "chore(recovery): v2.9.1-LIMPIO-2 - limpieza .git/objects + scripts recuperacion"
    & git commit -m $msg 2>&1 | ForEach-Object { W "    $_" }
    $sha = (& git rev-parse --short HEAD).Trim()
    & git tag -f "v2.9.1-LIMPIO-2" 2>&1 | Out-Null
    W "    Tag: v2.9.1-LIMPIO-2 -> $sha"
}

# ---------------------------------------------------------------- 6
W "`n[6] Log:"
& git log --oneline -5 2>&1 | ForEach-Object { W "    $_" }

W "`n[7] Working tree final:"
$st2 = @(& git status --short 2>&1)
if ($st2.Count -eq 0) { W "    LIMPIO" }
else { $st2 | Select-Object -First 15 | ForEach-Object { W "    $_" } }

# ---------------------------------------------------------------- 8
W "`n[8] Remoto:"
$existingRemote = (& git remote get-url origin 2>$null)
if ($existingRemote) {
    W "    origin ya existe: $existingRemote"
    if ($existingRemote -ne $REMOTE_URL) {
        W "    Actualizando URL a: $REMOTE_URL"
        & git remote set-url origin $REMOTE_URL 2>&1 | ForEach-Object { W "    $_" }
    }
} else {
    W "    Agregando origin: $REMOTE_URL"
    & git remote add origin $REMOTE_URL 2>&1 | ForEach-Object { W "    $_" }
}

# ---------------------------------------------------------------- 9
W "`n[9] Push a origin/main + tags (puede tardar varios minutos):"
& git push -u origin main --tags 2>&1 | ForEach-Object { W "    $_" }

# ---------------------------------------------------------------- 10
W "`n[10] Bundle final de respaldo:"
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bundlePath = Join-Path $env:TEMP "rf-final-$stamp.bundle"
& git bundle create $bundlePath --all 2>&1 | Out-Null
if (Test-Path $bundlePath) {
    $sizeMB = [math]::Round((Get-Item $bundlePath).Length / 1MB, 2)
    W "    OK: $bundlePath ($sizeMB MB)"
} else {
    W "    FALLO al crear bundle"
}

W "`n==================================================================="
W " FIN"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."