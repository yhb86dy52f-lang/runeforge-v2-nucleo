# =====================================================================
# RUNEFORGE_VERIFY_ALL.ps1
# Verificacion completa del estado del repo tras recuperacion
# Solo lectura. No modifica nada.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
$env:GIT_PAGER          = 'cat'
$env:GIT_TERMINAL_PROMPT = '0'

$Buf    = New-Object System.Collections.Generic.List[string]
$Checks = New-Object System.Collections.Generic.List[object]

function W($m)  { $Buf.Add([string]$m) | Out-Null; Write-Host $m }
function OK($n) { $Checks.Add([PSCustomObject]@{Item=$n;Status='OK'})   | Out-Null; W "  [OK]   $n" }
function FAIL($n,$d) { $Checks.Add([PSCustomObject]@{Item=$n;Status='FAIL'}) | Out-Null; W "  [FAIL] $n -> $d" }
function WARN($n,$d) { $Checks.Add([PSCustomObject]@{Item=$n;Status='WARN'}) | Out-Null; W "  [WARN] $n -> $d" }

W "==================================================================="
W " RUNEFORGE · VERIFICACION COMPLETA · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W " PWD: $(Get-Location)"
W "==================================================================="

# --- [1] Estamos en un repo git ---
W "`n[1] Repo git"
if (Test-Path ".git") { OK ".git presente" } else { FAIL ".git" "no existe"; }
$inside = (& git rev-parse --is-inside-work-tree 2>&1)
if ($inside -eq 'true') { OK "working tree valido" } else { FAIL "working tree" "$inside" }

# --- [2] Rama actual ---
W "`n[2] Rama actual"
$branch = (& git branch --show-current 2>&1)
W "    Rama: $branch"
if ($branch -eq 'recovery/v2.9.1-limpio') { OK "rama correcta" }
else { WARN "rama" "esperada recovery/v2.9.1-limpio, actual $branch" }

# --- [3] .git/objects limpio de desktop.ini ---
W "`n[3] Limpieza .git/objects"
$di = @(Get-ChildItem -Path ".git" -Recurse -File -Force -Filter "desktop.ini" -ErrorAction SilentlyContinue)
if ($di.Count -eq 0) { OK "sin desktop.ini dentro de .git/" }
else { WARN "desktop.ini en .git/" "quedan $($di.Count)" }

# --- [4] Refs rotos ---
W "`n[4] Refs rotos"
$fsckOut = @(& git fsck --full 2>&1)
$badRefs = @($fsckOut | Where-Object { $_ -match 'broken ref' })
if ($badRefs.Count -eq 0) { OK "sin broken refs" }
else { WARN "broken refs" "$($badRefs.Count) encontrados" }

$badSha = @($fsckOut | Where-Object { $_ -match 'bad sha1' })
if ($badSha.Count -eq 0) { OK "sin bad sha1" }
else { FAIL "bad sha1" "$($badSha.Count)" }

$errors = @($fsckOut | Where-Object { $_ -match 'error:' })
if ($errors.Count -eq 0) { OK "fsck sin errores" }
else { WARN "fsck" "$($errors.Count) errores" }

# --- [5] Tags presentes ---
W "`n[5] Tags"
$tags = @(& git tag 2>$null)
$required = @('v2.9.0-LIMPIO','v2.9.1-LIMPIO-2')
foreach ($t in $required) {
    if ($tags -contains $t) { OK "tag $t" }
    else { FAIL "tag $t" "no existe" }
}
$oldBad = @('v2.1.0')
foreach ($t in $oldBad) {
    if ($tags -contains $t) { WARN "tag $t" "aun existe (deberia haberse borrado)" }
    else { OK "tag $t ausente (correcto)" }
}

# --- [6] Commits esperados ---
W "`n[6] Commits recientes"
$log = @(& git log --oneline -5 2>&1)
$log | ForEach-Object { W "    $_" }
$head = (& git rev-parse --short HEAD 2>&1)
W "    HEAD = $head"
if ($log -match 'v2.9.1-LIMPIO-2') { OK "commit v2.9.1-LIMPIO-2 presente" }
else { FAIL "commit" "no se encuentra en log" }

# --- [7] README y MANIFIESTO ---
W "`n[7] Archivos criticos"
if (Test-Path "README.md")     { OK "README.md existe" } else { FAIL "README.md" "no existe" }
if (Test-Path "MANIFIESTO.md") { OK "MANIFIESTO.md existe" } else { FAIL "MANIFIESTO.md" "no existe" }

# --- [8] .gitignore ---
W "`n[8] .gitignore"
if (Test-Path ".gitignore") {
    $giSize = (Get-Item ".gitignore").Length
    W "    Tamano: $giSize bytes"
    if ($giSize -gt 1000) { OK ".gitignore robusto (>1 KB)" }
    else { WARN ".gitignore" "muy pequeño ($giSize bytes)" }
    # Verificar reglas clave
    $giContent = Get-Content ".gitignore" -Raw
    $keyRules = @('target/','node_modules/','venv/','__pycache__/','desktop.ini','*.bak','*.zip','models/')
    foreach ($r in $keyRules) {
        if ($giContent -match [regex]::Escape($r)) { OK "regla '$r' presente" }
        else { WARN "regla '$r'" "no encontrada en .gitignore" }
    }
} else { FAIL ".gitignore" "no existe" }

# --- [9] Tamano del repo ---
W "`n[9] Tamano del repo"
$co = & git count-objects -vH 2>&1
$co | ForEach-Object { W "    $_" }
$packLine = $co | Where-Object { $_ -match '^size-pack:' }
if ($packLine -match '([\d\.]+)\s*(MiB|GiB)') {
    $size = [double]$matches[1]
    $unit = $matches[2]
    $sizeMB = if ($unit -eq 'GiB') { $size * 1024 } else { $size }
    W "    size-pack en MB: $([math]::Round($sizeMB,2))"
    if ($sizeMB -lt 500)      { OK "repo ligero (<500 MB)" }
    elseif ($sizeMB -lt 1500) { OK "repo aceptable (<1.5 GB)" }
    else                      { WARN "repo" "size-pack alto ($sizeMB MB) - push puede fallar" }
}

# --- [10] Blobs gigantes residuales ---
W "`n[10] Blobs >50 MB residuales"
$packIdx = Get-ChildItem .git\objects\pack\*.idx -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
if ($packIdx) {
    $bigCount = 0
    $vp = & git verify-pack -v $packIdx 2>&1
    $vp | Where-Object { $_ -match '^\w{40} (blob|tree)' } | ForEach-Object {
        $parts = $_ -split '\s+'
        if ([int64]$parts[2] -gt 52428800) { $bigCount++ }
    }
    if ($bigCount -eq 0) { OK "sin blobs >50 MB" }
    else { WARN "blobs >50 MB" "$bigCount residuo(s)" }
} else { WARN "pack idx" "no se encuentra" }

# --- [11] Working tree ---
W "`n[11] Working tree"
$st = @(& git status --short 2>&1)
$staged    = ($st | Where-Object { $_ -match '^[AMD]' }).Count
$untracked = ($st | Where-Object { $_ -match '^\?\?' }).Count
$modified  = ($st | Where-Object { $_ -match '^ M' }).Count
W "    Staged: $staged | Modified: $modified | Untracked: $untracked"
$st | Select-Object -First 10 | ForEach-Object { W "    $_" }
if ($staged -eq 0 -and $untracked -eq 0) { OK "working tree limpio (excepto submodulos)" }
else { WARN "working tree" "$($st.Count) lineas en status" }

# --- [12] Remote ---
W "`n[12] Remote"
$rem = @(& git remote -v 2>&1)
if ($rem.Count -eq 0) { WARN "remote" "sin remoto configurado" }
else {
    $rem | ForEach-Object { W "    $_" }
    if ($rem -match 'yhb86dy52f-lang/runeforge-v2-nucleo') { OK "remote apunta al repo correcto" }
    else { WARN "remote" "URL inesperada" }
}

# --- [13] LFS ---
W "`n[13] Git LFS"
$lfsVer = & git lfs version 2>&1
if ($LASTEXITCODE -eq 0) {
    W "    $lfsVer"
    OK "git-lfs instalado"
    $lfsTracked = @(& git lfs ls-files 2>&1)
    W "    Archivos LFS trackeados: $($lfsTracked.Count)"
} else { WARN "git-lfs" "no disponible" }

# --- [14] Bundle de respaldo ---
W "`n[14] Bundles de respaldo en %TEMP%"
$bundles = @(Get-ChildItem "$env:TEMP\rf-*.bundle" -ErrorAction SilentlyContinue)
if ($bundles.Count -eq 0) { WARN "bundles" "ninguno encontrado" }
else {
    foreach ($b in $bundles) {
        $mb = [math]::Round($b.Length / 1MB, 2)
        W "    $($b.Name) · $mb MB · $($b.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))"
    }
    OK "$($bundles.Count) bundle(s) de respaldo"
}

# --- [15] Configuracion HTTP ---
W "`n[15] Configuracion HTTP git"
$httpVer  = (& git config --global http.version 2>$null)
$postBuf  = (& git config --global http.postBuffer 2>$null)
$sslVer   = (& git config --global http.sslVerify 2>$null)
W "    http.version    = $httpVer"
W "    http.postBuffer = $postBuf"
W "    http.sslVerify  = $sslVer"
if ($httpVer -eq 'HTTP/1.1') { OK "HTTP/1.1 configurado" } else { WARN "http.version" "no es HTTP/1.1" }
if ($postBuf -eq '524288000') { OK "postBuffer 500 MB" } else { WARN "postBuffer" "= $postBuf" }
if ($sslVer -eq 'false') { WARN "sslVerify" "verificacion TLS desactivada" }
else { OK "TLS verify activo" }

# --- [16] Identidad git ---
W "`n[16] Identidad git"
$uname = (& git config user.name 2>$null)
$umail = (& git config user.email 2>$null)
W "    user.name  = $uname"
W "    user.email = $umail"
if ($uname -and $umail) { OK "identidad configurada" } else { WARN "identidad" "falta user.name o user.email" }

# --- [17] Credenciales cacheadas ---
W "`n[17] Credenciales Windows"
$ck = cmdkey /list 2>&1 | Select-String -Pattern "git:https" -Context 0,3
if ($ck) {
    $ck | ForEach-Object { W "    $_" }
    WARN "credencial" "hay credencial git cacheada (puede ser de otra cuenta)"
} else { OK "sin credencial git:https cacheada" }

# =====================================================================
# RESUMEN
# =====================================================================
W ""
W "==================================================================="
W " RESUMEN"
W "==================================================================="
$okCount   = ($Checks | Where-Object { $_.Status -eq 'OK' }).Count
$warnCount = ($Checks | Where-Object { $_.Status -eq 'WARN' }).Count
$failCount = ($Checks | Where-Object { $_.Status -eq 'FAIL' }).Count
W " OK:   $okCount"
W " WARN: $warnCount"
W " FAIL: $failCount"

if ($failCount -gt 0) {
    W ""
    W " FALLOS:"
    $Checks | Where-Object { $_.Status -eq 'FAIL' } | ForEach-Object { W "   - $($_.Item)" }
}
if ($warnCount -gt 0) {
    W ""
    W " ADVERTENCIAS:"
    $Checks | Where-Object { $_.Status -eq 'WARN' } | ForEach-Object { W "   - $($_.Item)" }
}

W ""
if ($failCount -eq 0) {
    W " ESTADO: LISTO PARA PUSH"
} else {
    W " ESTADO: HAY FALLOS - revisar antes de push"
}

W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."