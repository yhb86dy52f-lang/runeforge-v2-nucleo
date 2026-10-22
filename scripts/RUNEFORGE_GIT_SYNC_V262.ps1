# =====================================================================
# RUNEFORGE_GIT_SYNC_V262.ps1
# Sincroniza la arquitectura local V2.6.2 con el repositorio remoto,
# aplicando un .gitignore estricto para evitar bloqueos por archivos
# pesados (CUDA DLLs, venv, node_modules) y forzando el push.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · SINCRONIZACIÓN GIT V2.6.2 · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$RepoDir = "C:\RUNEFORGE_V2_CORE"
$TargetUrl = "https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git"

Set-Location $RepoDir

# 1. Validar repositorio local
if (-not (Test-Path ".git")) {
    W "`n[FASE 1] Inicializando repositorio Git local..."
    cmd /c "git init -b main" | Out-Null
} else {
    W "`n[FASE 1] Repositorio Git local detectado."
}

# 2. Validar Remoto
W "`n[FASE 2] Configurando repositorio remoto..."
$currentRemote = cmd /c "git remote get-url origin 2>&1"
if ($currentRemote -ne $TargetUrl) {
    cmd /c "git remote remove origin 2>&1" | Out-Null
    cmd /c "git remote add origin $TargetUrl" | Out-Null
    W "  [+] Remoto configurado a $TargetUrl"
} else {
    W "  [=] Remoto ya estaba configurado correctamente."
}

# 3. Purga de LFS y .gitattributes previos
W "`n[FASE 3] Asegurando compilación ligera (Cero Bloat)..."
cmd /c "git lfs uninstall 2>&1" | Out-Null
if (Test-Path ".gitattributes") {
    Remove-Item ".gitattributes" -Force -ErrorAction SilentlyContinue
    W "  [+] .gitattributes eliminado para evitar rastreo LFS."
}

# 4. .gitignore Maestro
W "`n[FASE 4] Inyectando .gitignore estricto..."
$ignoreContent = @"
# SISTEMA
desktop.ini
Thumbs.db
.DS_Store

# ENTORNOS VIRTUALES Y DEPENDENCIAS
venv/
.venv/
env/
node_modules/
__pycache__/
*.pyc

# COMPILACIONES Y BINARIOS
target/
dist/
build/
out/
bin/
obj/
*.exe
*.dll
*.pdb
*.lib
*.so
*.dylib
*.whl
*.zip
*.tar.gz
*.iso
*.img
*.pt
*.pth
*.onnx
*.gguf
*.safetensors

# CACHÉS (SCCACHE, etc)
.sccache/
.cargo/

# BASURA Y LOGS
*.log
*.tmp
*.bak
*.bak.*
backups/
logs/
_archived_backups_*
"@
$ignoreContent | Set-Content -Path ".gitignore" -Encoding UTF8
W "  [+] .gitignore aplicado."

# 5. Rastrear archivos válidos
W "`n[FASE 5] Preparando archivos para el commit..."
cmd /c "git add -A" | Out-Null

# 6. Commit
W "`n[FASE 6] Creando commit de actualización..."
$commitMsg = "Update V2.6.2: Arquitectura completa (brain_hub, nexus-dashboard, tactical, scripts)"
cmd /c "git commit -m `"$commitMsg`" 2>&1" | ForEach-Object { W $_ }

# 7. Push Forzado
W "`n[FASE 7] Sincronizando con GitHub (esto puede tardar unos minutos)..."
cmd /c "git config --global http.postBuffer 1048576000" | Out-Null
cmd /c "git config --global http.version HTTP/1.1" | Out-Null

$pushOut = cmd /c "git push origin main -f --verbose 2>&1"
W "  [>] Resultado del Push:"
foreach ($line in ($pushOut -split "`n")) {
    if ($line -match "error|fatal|forced update|Writing objects|Total|Everything up-to-date") {
        W "    $line"
    }
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Arquitectura V2.6.2 consolidada y enviada."
W " Si el push dice 'forced update', el repositorio remoto ya cuenta"
W " con los módulos de Telemetría, Dashboard, Táctica y Scripts."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
