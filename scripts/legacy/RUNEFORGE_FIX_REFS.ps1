# =====================================================================
# RUNEFORGE_FIX_REFS.ps1
# Limpia refs rotos (desktop.ini en .git/refs) + verifica repo + bundle
# Ejecutar desde: C:\RUNEFORGE_V2_CORE
# =====================================================================
$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
$env:GIT_PAGER          = 'cat'
$env:GIT_TERMINAL_PROMPT = '0'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · FIX REFS · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

if (-not (Test-Path ".git")) {
    W "ERROR: no hay .git aqui. Abortando."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# --- 1. Detectar refs rotos ---
W "`n[1] Refs actuales en .git/refs:"
if (Test-Path ".git\refs") {
    $refs = Get-ChildItem -Path ".git\refs" -Recurse -File -Force -ErrorAction SilentlyContinue
    if ($refs) { $refs | ForEach-Object { W "    $($_.FullName.Replace((Get-Location).Path + '\',''))" } }
    else { W "    (vacio)" }
} else {
    W "    .git/refs no existe (packed-refs?)"
}

# --- 2. Borrar desktop.ini dentro de .git/refs ---
W "`n[2] Buscando y borrando desktop.ini en .git/refs..."
$borrados = 0
$targets = @(
    ".git\refs\desktop.ini",
    ".git\refs\tags\desktop.ini",
    ".git\refs\heads\desktop.ini",
    ".git\refs\remotes\desktop.ini"
)
foreach ($t in $targets) {
    if (Test-Path -LiteralPath $t) {
        Remove-Item -LiteralPath $t -Force -ErrorAction SilentlyContinue
        W "    Borrado: $t"
        $borrados++
    }
}
# Barrido recursivo por si hay mas
Get-ChildItem -Path ".git\refs" -Recurse -File -Force -Filter "desktop.ini" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
    W "    Borrado (recursivo): $($_.FullName)"
    $borrados++
}
# Tambien en la raiz de .git
if (Test-Path -LiteralPath ".git\desktop.ini") {
    Remove-Item -LiteralPath ".git\desktop.ini" -Force -ErrorAction SilentlyContinue
    W "    Borrado: .git\desktop.ini"
    $borrados++
}
W "    Total borrados: $borrados"

# --- 3. Limpiar el archivo packed-refs si tiene desktop.ini ---
$packedRefs = ".git\packed-refs"
if (Test-Path $packedRefs) {
    $content = Get-Content $packedRefs -Raw
    if ($content -match 'desktop\.ini') {
        W "`n[3] Limpiando packed-refs..."
        $lineas = Get-Content $packedRefs | Where-Object { $_ -notmatch 'desktop\.ini' }
        [System.IO.File]::WriteAllLines((Resolve-Path $packedRefs), $lineas)
        W "    packed-refs limpiado"
    } else {
        W "`n[3] packed-refs OK (sin desktop.ini)"
    }
}

# --- 4. Verificar fsck ---
W "`n[4] git fsck --full:"
$fsck = & git fsck --full 2>&1
if ($fsck) { $fsck | ForEach-Object { W "    $_" } } else { W "    (sin errores)" }

# --- 5. Verificacion git tags ---
W "`n[5] Tags en HEAD:"
$tagsHead = & git tag --points-at HEAD 2>&1
if ($tagsHead) { $tagsHead | ForEach-Object { W "    $_" } } else { W "    (sin tags)" }

W "`n[6] Log reciente:"
& git log --oneline -3 2>&1 | ForEach-Object { W "    $_" }

W "`n[7] Working tree:"
$st = @(& git status --short 2>&1)
W "    Lineas en status: $($st.Count)"
$st | Select-Object -First 10 | ForEach-Object { W "    $_" }

# --- 8. Bundle de respaldo ---
W "`n[8] Creando bundle de respaldo..."
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bundlePath = Join-Path $env:TEMP "rf-backup-$stamp.bundle"
$bundleOut = & git bundle create $bundlePath --all 2>&1
if (Test-Path $bundlePath) {
    $sizeMB = [math]::Round((Get-Item $bundlePath).Length / 1MB, 2)
    W "    OK: $bundlePath ($sizeMB MB)"
} else {
    W "    FALLO bundle:"
    $bundleOut | ForEach-Object { W "    $_" }
}

# --- 9. Remoto ---
W "`n[9] Remoto:"
$rem = & git remote -v 2>&1
if ($rem) { $rem | ForEach-Object { W "    $_" } }
else      { W "    (sin remoto configurado)" }

W "`n==================================================================="
W " FIN"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."