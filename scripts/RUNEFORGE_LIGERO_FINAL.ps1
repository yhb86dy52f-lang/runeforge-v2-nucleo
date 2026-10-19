# =====================================================================
# RUNEFORGE_LIGERO_FINAL.ps1
# Mueve los archivos >20MB fuera del repo, actualiza .gitignore,
# reinicia Git y hace un push ligero configurando el buffer HTTP.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · ADELGAZAMIENTO EXTREMO Y PUSH · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
$BigFilesDir = "C:\RUNEFORGE_BIG_FILES_ARCHIVE"
Set-Location $GitRoot

# 1. Matar procesos
W "`n[FASE 1] Matando procesos de Git..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Mover archivos pesados (>20MB) fuera del repositorio
W "`n[FASE 2] Buscando y aislando archivos pesados (Esto puede tardar un poco)..."
New-Item -ItemType Directory -Force -Path $BigFilesDir | Out-Null
$largeFiles = Get-ChildItem -Path $GitRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 20MB -and $_.FullName -notmatch '\\.git\\' }

foreach ($file in $largeFiles) {
    try {
        Move-Item -Path $file.FullName -Destination $BigFilesDir -Force -ErrorAction Stop
        W "  [+] Movido fuera del repo: $($file.Name) ($([math]::Round($file.Length/1MB, 2)) MB)"
    } catch {
        W "  [!] No se pudo mover: $($file.Name)"
    }
}

# 3. Crear un .gitignore robusto
W "`n[FASE 3] Configurando .gitignore definitivo..."
$ignoreContent = @"
# SISTEMA Y CARPETAS
desktop.ini
Thumbs.db
node_modules/
__pycache__/
venv/
.env
.venv/

# ARCHIVOS PESADOS (Movidos a C:\RUNEFORGE_BIG_FILES_ARCHIVE)
*.whl
*.zip
*.tar.gz
*.exe
*.bin
*.iso
*.pth
*.onnx
*.gguf
*.ckpt
*.safetensors
*.bak
*.bak.*

# CARPETAS DE COMPILACION
target/
dist/
build/
out/
bin/
obj/
"@
$ignoreContent | Set-Content -Path "$GitRoot\.gitignore" -Encoding UTF8

# 4. Destruir el .git actual y crear uno nuevo
W "`n[FASE 4] Reiniciando el repositorio Git desde cero..."
if (Test-Path "$GitRoot\.git") {
    cmd /c "rd /s /q .git" 2>$null
    if (Test-Path "$GitRoot\.git") { [System.IO.Directory]::Delete("$GitRoot\.git", $true) }
}
cmd /c "git init -b main" | Out-Null
cmd /c "git remote add origin https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git" | Out-Null

# 5. Configurar Git para evitar HTTP 500
W "`n[FASE 5] Configurando buffer de red de Git..."
cmd /c "git config --global http.postBuffer 524288000" | Out-Null
cmd /c "git config --global http.lowSpeedLimit 0" | Out-Null
cmd /c "git config --global http.lowSpeedTime 999999" | Out-Null

# 6. Preparar el commit
W "`n[FASE 6] Agregando archivos (Solo código ligero)..."
cmd /c "git add ." | Out-Null
cmd /c "git commit -m `"RUNEFORGE: Repositorio purgado de archivos pesados`"" | Out-Null

# 7. Push
W "`n[FASE 7] Subiendo a GitHub (Ahora debería ser súper rápido)..."
$pushOut = cmd /c "git push origin main --force 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Los archivos gigantes (.whl, .pth, etc.) se movieron a:"
W "    $BigFilesDir"
W " 2. El .gitignore evitará que vuelvan a rastrearse."
W " 3. Se reinició Git y se forzó un push ligero."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."