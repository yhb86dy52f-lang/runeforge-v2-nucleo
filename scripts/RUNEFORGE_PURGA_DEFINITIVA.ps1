# =====================================================================
# RUNEFORGE_PURGA_DEFINITIVA.ps1
# Destruye la carpeta .git, elimina los archivos .gitattributes que 
# activan LFS, y fuerza una subida limpia por HTTP normal.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · PURGA DEFINITIVA DE LFS · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Matar procesos
W "`n[FASE 1] Matando procesos de Git y LFS..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "git-lfs" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
W "[+] Listo."

# 2. Destruir la carpeta .git
W "`n[FASE 2] Destruyendo carpeta .git..."
if (Test-Path "$GitRoot\.git") {
    cmd /c "attrib -r -h -s .git /s /d" 2>$null
    cmd /c "rd /s /q .git" 2>$null
    if (Test-Path "$GitRoot\.git") {
        [System.IO.Directory]::Delete("$GitRoot\.git", $true)
    }
    W "[+] Carpeta .git destruida."
}

# 3. Destruir archivos .gitattributes (El origen del problema LFS)
W "`n[FASE 3] Eliminando archivos .gitattributes que rastrean LFS..."
$attrFiles = Get-ChildItem -Path $GitRoot -Filter ".gitattributes" -Recurse -File -ErrorAction SilentlyContinue
foreach ($file in $attrFiles) {
    # Eliminamos solo si contienen la palabra LFS para no romper otras cosas
    if ((Get-Content $file.FullName -Raw) -match "filter=lfs") {
        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
        W "  [+] Eliminado: $($file.FullName)"
    }
}
W "[+] Archivos de configuración de LFS erradicados."

# 4. Reinicializar Git
W "`n[FASE 4] Creando un repositorio Git completamente nuevo..."
cmd /c "git init -b main" | Out-Null
cmd /c "git remote add origin https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git" | Out-Null
W "[+] Repositorio inicializado."

# 5. Preparar archivos
W "`n[FASE 5] Preparando archivos (Git los tratará como binarios normales)..."
cmd /c "git add ." | Out-Null
cmd /c "git commit -m `"RUNEFORGE: Initial Clean Commit - Purga de LFS eliminada`"" | Out-Null
W "[+] Archivos preparados."

# 6. Push
W "`n[FASE 6] Subiendo el repositorio limpio a GitHub..."
$pushOut = cmd /c "git push origin main --force 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se erradicó el archivo .gitattributes que activaba LFS."
W " 2. Se creó un repositorio limpio."
W " 3. Si el push dice 'forced update', GitHub está finalmente libre"
W "    de los 2.3 GB de basura."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."