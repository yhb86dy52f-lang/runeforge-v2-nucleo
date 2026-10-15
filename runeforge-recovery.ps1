# =====================================================================
# RUNEFORGE · RECOVERY ONE-SHOT · v2.9.0-LIMPIO (FIXED)
# Guardar como: $env:TEMP\runeforge-recovery.ps1
# Ejecutar:     powershell -ExecutionPolicy Bypass -NoProfile -File $env:TEMP\runeforge-recovery.ps1
# =====================================================================
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }
function Git($a) { & git @a 2>&1 | ForEach-Object { "$_" } }

W "==================================================================="
W " RUNEFORGE RECOVERY · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W " PWD: $(Get-Location)"
W "==================================================================="

if (-not (Test-Path (Join-Path (Get-Location) '.git'))) {
    W "ERROR: no hay .git. Abortando."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}
if ((git rev-parse --is-inside-work-tree 2>&1) -ne 'true') {
    W "ERROR: no es working tree git."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

$existing = git tag -l 'v2.9.0-LIMPIO'
if ($existing) {
    W "`n[0] Tag v2.9.0-LIMPIO ya existe. Nada que hacer."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 1. Revertir commit malo si aplica ---
$tagsAtHead = @(git tag --points-at HEAD 2>$null)
W "`n[1] HEAD: $(git rev-parse --short HEAD)"
W "    Tags en HEAD: $($tagsAtHead -join ', ')"

if ($tagsAtHead -contains 'v2.1.0') {
    W "    [!] Revirtiendo commit v2.1.0"
    Git @('reset','--soft','HEAD~1') | ForEach-Object { W "    $_" }
    Git @('reset') | Out-Null
    git tag -d v2.1.0 2>&1 | Out-Null
    $parent = (git rev-parse HEAD).Trim()
    Git @('checkout',$parent,'--','README.md','MANIFIESTO.md') | Out-Null
    W "    OK. Nuevo HEAD: $(git rev-parse --short HEAD)"
} else {
    W "    Sin commit malo. Continuando."
}

# --- 2. .gitignore v2.2 sin BOM ---
$giPath = Join-Path (Get-Location) '.gitignore'
$gi = @'
# ====================================================================
# RUNEFORGE V2.2 - .gitignore definitivo
# ====================================================================
target/
**/target/
**/src-tauri/target/
node_modules/
**/node_modules/
dist/
**/dist/
build/
**/build/
build-cuda/
.next/
out/
.sccache/
.cargo/
node_modules/.cache/

__pycache__/
**/__pycache__/
*.py[cod]
*.pyo
*.pyd
venv/
**/venv/
.venv/
**/.venv/
env/
ENV/
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/

**/*.rs.bk
Cargo.lock.bak

models/
**/models/
*.bin
*.gguf
*.onnx
*.pt
*.pth
*.safetensors
*.exe
*.msi
*.dll
*.so
*.dylib
*.node

BACKUP-*.zip
*.zip
*.7z
*.rar
*.tar
*.tar.gz
*.tgz
*.bak
*.bak_*
*.bak.*
*.bak2
*.bak3
*.VIEJO_*
*.old
*.orig
*.tmp
*.temp
*~

*.sqlite
*.sqlite-wal
*.sqlite-shm
*.db
*.db-wal
*.db-shm
data/
db/
infra/headscale/data/
infra/headscale/config/data/
*.3u
knowledge/devices/audit-*.txt
knowledge/devices/*.plist

.env
.env.*
*.env
app.env
*.pem
*.key
id_rsa*
ssh_host_*_key
secrets/
*.backup_whatsapp
selfIdentity.plist

ecosystem.config.js
ecosystem.config.js.bak_*
appsettings.local.json

*.log
*.log.err
logs/
*.log.txt
runeforge_orquestador_log.txt
server_run.log
server_run.log.err
forward.log
tunnel.log
wda.log
tailscale.log
diagnostico_flota.log

desktop.ini
**/desktop.ini
Thumbs.db
.DS_Store
*.lnk

.obsidian/
.vscode/
*.code-workspace

.tmp.driveupload/
clippings/

.pm2/
pids/

status.txt
videoframe_*.png
Nuevo documento de texto.txt
Sin título.*
2026-09-13.md
e --abort
Administador_*.txt
Administrador_*.txt
'@
[System.IO.File]::WriteAllText($giPath, $gi, (New-Object System.Text.UTF8Encoding($false)))
W "`n[2] .gitignore escrito SIN BOM: $((Get-Content .gitignore).Count) lineas"

# --- 2b. Preview de trackeados que saldran del indice ---
$tracked = @(git ls-files)
$willDrop = @()
foreach ($f in $tracked) {
    git check-ignore -q -- $f 2>$null
    if ($LASTEXITCODE -eq 0) { $willDrop += $f }
}
W "`n[2b] Trackeados actuales: $($tracked.Count)"
W "     Seran removidos del indice (quedan en disco): $($willDrop.Count)"
$willDrop | Select-Object -First 25 | ForEach-Object { W "       - $_" }
if ($willDrop.Count -gt 25) { W "       ... y $($willDrop.Count - 25) mas" }

# --- 3. Limpiar indice (conserva disco) ---
git rm -r --cached . --quiet 2>&1 | Out-Null
W "`n[3] Indice limpiado"

# --- 4. Re-add ---
git add -A 2>&1 | Out-Null
W "[4] git add -A aplicado"

# --- 5. Verificaciones ---
W "`n[5] VERIFICACIONES"
$st = @(git status --short)
W "    Lineas status:   $($st.Count)"
W "    Staged (A/M/D):  $(($st | Where-Object { $_ -match '^[AMD]' }).Count)"
W "    Untracked (??):  $(($st | Where-Object { $_ -match '^\?\?' }).Count)"

W "`n    Chequeo de pesados:"
$chequeos = @('target/','node_modules/','models/','venv/','__pycache__/','BACKUP-','.sccache/','build-cuda/','ggml-','.dll','.exe','.msi')
foreach ($c in $chequeos) {
    $hit = $st | Select-String -SimpleMatch $c
    if ($hit) { W "      X ENTRO: $c  ($($hit.Count) hits)" }
    else      { W "      OK no entra: $c" }
}

# --- 6. Commit + tag ---
W "`n[6] COMMIT"
$stagedNames = @(git diff --cached --name-only)
if ($stagedNames.Count -eq 0) {
    W "    Nada staged. No se commitea."
} else {
    W "    Archivos staged: $($stagedNames.Count)"
    $msg = "feat(recovery): v2.9.0-LIMPIO - README+MANIFIESTO restaurados + .gitignore v2.2 + limpieza de indice"
    Git @('commit','-m',$msg) | ForEach-Object { W "    $_" }
    $sha = (git rev-parse --short HEAD).Trim()
    git tag -f 'v2.9.0-LIMPIO' 2>&1 | Out-Null
    W "    Tag aplicado: v2.9.0-LIMPIO -> $sha"
}

# --- 7. Estado final ---
W "`n[7] ULTIMOS COMMITS"
git log --oneline -6 | ForEach-Object { W "    $_" }

W "`n[8] TAGS RECIENTES"
git tag --sort=-creatordate 2>$null | Select-Object -First 8 | ForEach-Object { W "    $_" }

W "`n[9] REMOTO"
$rem = git remote -v
if ($rem) { $rem | ForEach-Object { W "    $_" } }
else      { W "    (sin remoto configurado - push omitido)" }

W "`n==================================================================="
W " FIN · Salida copiada al portapapeles"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")