$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$capture = New-Object System.Collections.ArrayList
function Log { param($msg, $color="Gray") Write-Host $msg -ForegroundColor $color; $null = $capture.Add($msg) }

Log "=== RUNEFORGE GIT SYNC ===" "Cyan"
Log "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "DarkGray"
Log ""

Set-Location "C:\RUNEFORGE_V2_CORE"

# 1. Asegurar .gitignore (Solo si no existe, para no sobrescribir el tuyo pro)
if (-not (Test-Path ".gitignore")) {
    $gitignore = @"
venv/
node_modules/
target/
dist/
*.log
logs/
.env
__pycache__/
*.exe
*.dll
*.bak
"@
    [System.IO.File]::WriteAllText("C:\RUNEFORGE_V2_CORE\.gitignore", $gitignore, (New-Object System.Text.UTF8Encoding $true))
    Log "[OK] Archivo .gitignore básico creado." "Green"
}

# 2. Verificar si el repositorio Git existe
if (-not (Test-Path ".git")) {
    Log "[!] Inicializando repositorio Git..." "Yellow"
    git init
    git branch -M main
    git remote add origin https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git
    Log "[OK] Repositorio Git inicializado." "Green"
}

# 3. Verificar si hay cambios reales para evitar bloqueos
Log "[*] Buscando cambios locales..." "Yellow"
$status = git status --porcelain

if ([string]::IsNullOrWhiteSpace($status)) {
    Log "`n[OK] El repositorio ya está actualizado. No hay nada nuevo que subir." "Green"
    $capture -join "`r`n" | Set-Clipboard
    Log "`n[OK] Reporte copiado al portapapeles (Ctrl+V)." "Cyan"
    return
}

# 4. Git Add y Commit
Log "[*] Preparando archivos..." "Yellow"
git add .

$commitMsg = "Actualización RUNEFORGE - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Log "[*] Haciendo commit: $commitMsg" "Yellow"
$commitResult = git commit -m "$commitMsg" 2>&1
Log $commitResult "DarkGray"

# 5. Push (Forzado para evitar bloqueos por upstream)
Log "`n[*] Subiendo a GitHub (Origin/Main)..." "Yellow"
# Usamos cmd.exe /c para silenciar advertencias de consola y forzar el push
$pushResult = cmd.exe /c "git push -f origin main 2>&1"

if ($LASTEXITCODE -eq 0) {
    Log "`n[OK] Sincronización completada con éxito. Tu ecosistema está a salvo." "Green"
} else {
    Log "`n[X] ERROR al subir a GitHub:" "Red"
    Log $pushResult "DarkRed"
    Log "Posibles causas: Credenciales caducadas, conflicto de ramas o falta de conexión." "Yellow"
}

# 6. Regla Canónica
$capture -join "`r`n" | Set-Clipboard
Log "`n[OK] Reporte completo copiado al portapapeles (Ctrl+V)." "Cyan"