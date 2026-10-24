# =====================================================================
# RUNEFORGE_FIX_JEKYLL.ps1
# Elimina el workflow Jekyll que falla (no aplica a stack Fastify+PWA)
# =====================================================================

$ErrorActionPreference   = 'Continue'
$ProgressPreference      = 'SilentlyContinue'
$env:GIT_PAGER           = 'cat'
$env:GIT_TERMINAL_PROMPT = '0'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · FIX JEKYLL WORKFLOW · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

Set-Location C:\RUNEFORGE_V2_CORE

# --- 1. Estado actual ---
W "`n[1] Estado actual"
W "    Rama: $(git branch --show-current)"
W "    HEAD: $(git rev-parse --short HEAD)"

# --- 2. Actualizar main local con remoto (shallow) ---
W "`n[2] Fetch main remoto (shallow)"
& git fetch --depth=1 origin main 2>&1 | ForEach-Object { W "    $_" }

W "`n[3] Reset local main a origin/main"
& git checkout main 2>&1 | ForEach-Object { W "    $_" }
& git reset --hard origin/main 2>&1 | ForEach-Object { W "    $_" }
W "    HEAD local: $(git rev-parse --short HEAD)"

# --- 4. Ver workflow Jekyll ---
$workflowPath = ".github\workflows\jekyll-gh-pages.yml"
W "`n[4] Buscando $workflowPath"
if (Test-Path $workflowPath) {
    W "    Existe. Eliminando..."
    Remove-Item $workflowPath -Force
    W "    Borrado."
} else {
    W "    No existe. Nada que borrar."
    # Listar workflows presentes
    $wfs = @(Get-ChildItem ".github\workflows" -File -ErrorAction SilentlyContinue)
    if ($wfs.Count -gt 0) {
        W "    Workflows actuales:"
        $wfs | ForEach-Object { W "      - $($_.Name)" }
    }
}

# --- 5. Ver si hay mas workflows Jekyll ---
W "`n[5] Escaneo de otros workflows Jekyll"
$allWfs = @(Get-ChildItem ".github\workflows" -File -ErrorAction SilentlyContinue)
foreach ($wf in $allWfs) {
    $content = Get-Content $wf.FullName -Raw
    if ($content -match 'jekyll' -or $content -match 'pages-build-deployment') {
        W "    Detectado Jekyll en: $($wf.Name)"
        Remove-Item $wf.FullName -Force
        W "    Borrado."
    }
}

# --- 6. Commit + push ---
W "`n[6] Stage + commit + push"
$st = @(& git status --short 2>&1)
if ($st.Count -eq 0) {
    W "    Nada que commitear."
} else {
    & git add -A 2>&1 | Out-Null
    & git commit -m "chore(ci): eliminar workflow Jekyll (stack Fastify+PWA, no Jekyll)" 2>&1 | ForEach-Object { W "    $_" }

    W "    Push a origin/main..."
    & git push origin main 2>&1 | ForEach-Object { W "    $_" }
}

# --- 7. Verificacion ---
W "`n[7] Estado final"
W "    HEAD: $(git rev-parse --short HEAD)"
W "    Log:"
& git log --oneline -3 2>&1 | ForEach-Object { W "      $_" }

W "`n    Workflows restantes:"
$remaining = @(Get-ChildItem ".github\workflows" -File -ErrorAction SilentlyContinue)
if ($remaining.Count -eq 0) { W "      (ninguno)" }
else { $remaining | ForEach-Object { W "      - $($_.Name)" } }

W "`n==================================================================="
W " FIN"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."