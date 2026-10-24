$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "[*] Iniciando sincronización con GitHub..." -ForegroundColor Cyan
Set-Location "C:\RUNEFORGE_V2_CORE"

# 1. Crear o actualizar el .gitignore para proteger dependencias
$gitignore = @"
# RUNEFORGE IGNORE
venv/
node_modules/
target/
dist/
*.log
logs/
.env
__pycache__/
"@
if (-not (Test-Path ".gitignore")) {
    [System.IO.File]::WriteAllText("C:\RUNEFORGE_V2_CORE\.gitignore", $gitignore, (New-Object System.Text.UTF8Encoding $true))
    Write-Host "[OK] Archivo .gitignore creado." -ForegroundColor Green
}

# 2. Verificar si el repositorio Git existe localmente
if (-not (Test-Path ".git")) {
    Write-Host "[!] No se detectó repositorio local. Inicializando Git..." -ForegroundColor Yellow
    git init
    git branch -M main
    git remote add origin https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git
    Write-Host "[OK] Repositorio Git inicializado y vinculado." -ForegroundColor Green
}

# 3. Git Add, Commit y Push
Write-Host "[*] Agregando archivos..." -ForegroundColor Yellow
git add .

$commitMsg = "Actualización RUNEFORGE V2.6.2 - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "[*] Haciendo commit: $commitMsg..." -ForegroundColor Yellow
$commitResult = git commit -m "$commitMsg" 2>&1
Write-Host $commitResult -ForegroundColor DarkGray

Write-Host "[*] Subiendo a la nube (GitHub)..." -ForegroundColor Yellow
$pushResult = git push -u origin main 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[OK] Sincronización completada con éxito. Tu ecosistema está a salvo." -ForegroundColor Green
} else {
    Write-Host "`n[X] ERROR al subir a GitHub. Revisa los detalles:" -ForegroundColor Red
    Write-Host $pushResult -ForegroundColor DarkRed
    Write-Host "Posibles causas: Credenciales caducadas, conflicto de ramas o falta de conexión." -ForegroundColor Yellow
}