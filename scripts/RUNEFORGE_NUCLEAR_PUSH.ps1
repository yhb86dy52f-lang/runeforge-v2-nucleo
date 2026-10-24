# =====================================================================
# RUNEFORGE_NUCLEAR_PUSH.ps1
# Purga total de LFS, .gitattributes, historial local y forzado de push
# con configuraciones de red para evitar HTTP 408/500.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · PURGA NUCLEAR Y PUSH MAESTRO · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Matar procesos de Git
W "`n[FASE 1] Matando procesos de Git..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "git-lfs" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "git-remote-https" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
W "[+] Procesos detenidos."

# 2. Destruir .git y .gitattributes
W "`n[FASE 2] Destruyendo .git y .gitattributes..."
if (Test-Path "$GitRoot\.git") {
    cmd /c "attrib -r -h -s .git /s /d" 2>$null
    cmd /c "rd /s /q .git" 2>$null
    if (Test-Path "$GitRoot\.git") { [System.IO.Directory]::Delete("$GitRoot\.git", $true) }
    W "[+] Carpeta .git destruida."
}

$attrFiles = Get-ChildItem -Path $GitRoot -Filter ".gitattributes" -Recurse -File -ErrorAction SilentlyContinue
foreach ($file in $attrFiles) {
    Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
    W "[+] Eliminado: $($file.FullName)"
}

# 3. Re-inicializar Git y configurar red
W "`n[FASE 3] Inicializando repositorio y configurando red..."
cmd /c "git init -b main" | Out-Null
cmd /c "git remote add origin https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git" | Out-Null

cmd /c "git config --global http.version HTTP/1.1" | Out-Null
cmd /c "git config --global http.postBuffer 1048576000" | Out-Null
cmd /c "git config --global core.compression 9" | Out-Null
cmd /c "git config --global http.lowSpeedLimit 0" | Out-Null
cmd /c "git config --global http.lowSpeedTime 999999" | Out-Null
W "[+] Red configurada (HTTP/1.1, 1GB Buffer, Compresión 9)."

# 4. Crear .gitignore maestro
W "`n[FASE 4] Creando .gitignore maestro..."
$ignoreContent = @"
# SISTEMA
desktop.ini
Thumbs.db
.DS_Store

# ENTORNOS
node_modules/
venv/
.env
.venv/
__pycache__/
*.pyc
target/
dist/
build/
out/
bin/
obj/

# BINARIOS Y PESADOS
*.whl
*.zip
*.tar.gz
*.exe
*.dll
*.pdb
*.lib
*.so
*.dylib
*.iso
*.img
*.bak
*.bak.*
*.log
*.tmp

# BASURA
backups/
_archived_backups_*
logs/
"@
$ignoreContent | Set-Content -Path "$GitRoot\.gitignore" -Encoding UTF8
W "[+] .gitignore creado."

# 5. Add, Commit y Push
W "`n[FASE 5] Agregando archivos y forzando Push..."
cmd /c "git add ." | Out-Null
cmd /c "git commit -m `"RUNEFORGE: Purga Nuclear - Reset de historial y push limpio`"" | Out-Null

$pushOut = cmd /c "git push origin main -f 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Si el push dice 'forced update', GitHub está limpio."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
