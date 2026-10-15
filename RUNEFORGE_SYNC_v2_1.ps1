param(
  [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"
Set-Location "C:\RUNEFORGE_V2_CORE"

Write-Host "== RUNEFORGE V2.1 SYNC - ANALISIS LOCAL vs GITHUB ==" -ForegroundColor Green
Write-Host "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

# 1. Estado Git
Write-Host "`n[1] Estado Git actual" -ForegroundColor Yellow
git fetch origin
git status --short
Write-Host "`nUltimos commits:"
git log --oneline --decorate --graph -8

Write-Host "`nDiferencia con origin/main:"
git diff origin/main --stat

# 2. Estructura top-level sin node_modules/target
Write-Host "`n[2] Estructura limpia (top 2 niveles sin artefactos)" -ForegroundColor Yellow
Get-ChildItem -Force | Where-Object { $_.Name -notin @('node_modules','target','dist','.git','.cargo') } | Format-Table Name, @{N='Tipo';E={if($_.PSIsContainer){'DIR'}else{'FILE'}}}, Length, LastWriteTime -AutoSize

if (Test-Path ".\src") {
  Write-Host "`n-- src/ --" -ForegroundColor Cyan
  Get-ChildItem ".\src" -Force | Where-Object { $_.Name -notin @('node_modules','target','dist') } | Format-Table Name, @{N='Tipo';E={if($_.PSIsContainer){'DIR'}else{'FILE'}}} -AutoSize
  if (Test-Path ".\src\backend") {
    Write-Host "`n-- src/backend --"
    Get-ChildItem ".\src\backend" -Force | Where-Object { $_.Name -notin @('node_modules','dist') } | Select-Object Name, Length | Format-Table -AutoSize
  }
}

# Detectar nuevos proyectos Tauri
Write-Host "`n[3] Proyectos Tauri detectados" -ForegroundColor Yellow
Get-ChildItem -Recurse -Depth 3 -Filter "tauri.conf.json" -ErrorAction SilentlyContinue | ForEach-Object {
  Write-Host " - $($_.DirectoryName)" -ForegroundColor White
}

# 3. Archivos grandes >50MB que NO deben ir a Git
Write-Host "`n[4] Archivos >50MB (candidatos a .gitignore o LFS)" -ForegroundColor Yellow
Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 50MB -and $_.FullName -notlike "*\target\*" -and $_.FullName -notlike "*\.git\*" } | Sort-Object Length -Descending | Select-Object FullName, @{N='MB';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime | Format-Table -AutoSize

# 4. Chequeo secretos
Write-Host "`n[5] Chequeo secretos (NO debe haber coincidencias)" -ForegroundColor Yellow
$patterns = @("*.env","*.pem","*id_rsa*","ssh_host_*_key","*.backup_whatsapp","app.env","*.key")
foreach ($pat in $patterns) {
  $found = Get-ChildItem -Recurse -Filter $pat -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notlike "*\target\*" -and $_.FullName -notlike "*\.git\*" } | Select-Object -First 5
  if ($found) {
    Write-Host " ALERTA $pat :" -ForegroundColor Red
    $found | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor Red }
  }
}

# 5. .gitignore v2.1 propuesto
Write-Host "`n[6] Generando .gitignore v2.1 si no existe .gitignore.v2.1" -ForegroundColor Yellow
$gitignore_v21 = @"
# === RUNEFORGE V2.1 - Artefactos ===
target/
**/target/
**/src-tauri/target/
node_modules/
**/node_modules/
dist/
**/dist/
build/
.next/
out/

# Rust / Cargo
**/*.rs.bk
Cargo.lock.bak
.cargo/

# Logs y OS
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.DS_Store
Thumbs.db
*.tmp
*.temp

# Secrets - NUNCA commitear
.env
.env.*
*.env
app.env
*.pem
*.key
id_rsa*
ssh_host_*_key
*.backup_whatsapp
secrets/
knowledge/devices/audit-*.txt
knowledge/devices/*.plist

# Config local con rutas absolutas
ecosystem.config.js
ecosystem.config.js.bak_*
appsettings.local.json

# Backups
*.bak
*.backup
*.old

# PM2
.pm2/
pids/
logs/

# 3uTools / dumps
*.3u
Administador_*.txt
"@

if (-not (Test-Path ".\.gitignore.v2.1")) {
  $gitignore_v21 | Set-Content ".\.gitignore.v2.1" -Encoding UTF8
  Write-Host " Creado .gitignore.v2.1" -ForegroundColor Green
}

# Comparar con actual
Write-Host "`n.gitignore actual:"
Get-Content ".\.gitignore" | Write-Host -ForegroundColor Gray

# 6. Propuesta de commit
Write-Host "`n[7] Propuesta de estructura para commit v2.1" -ForegroundColor Yellow
Write-Host @"
Si todo esta limpio, ejecuta:

git add .gitignore.v2.1
Copy-Item .\.gitignore.v2.1 .\.gitignore -Force
git add .gitignore knowledge/ src/ public/ scripts/ MANIFIESTO.md README.md LICENSE
git status --short  # revisa que NO entren target/, node_modules/, dist/
git commit -m "feat: v2.1 - nexus-lab + openwash-real + knowledge/devices + .gitignore blindado + docs actualizados"
git tag v2.1.0
git push origin main --tags

Si el repo pesa >100MB, activa LFS antes:
git lfs install
git lfs track "*.exe"
git lfs track "*.msi"
git lfs track "*.dll"
git add .gitattributes
"@

if (-not $DryRun) {
  # Generar reporte
  $reportPath = ".\knowledge\devices\SYNC_REPORT_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').md"
  New-Item -ItemType Directory -Force -Path ".\knowledge\devices" | Out-Null
  $report = @"
# RUNEFORGE V2.1 - Reporte de Sincronizacion
Fecha: $(Get-Date)
Host: $env:COMPUTERNAME User: $env:USERNAME

## Git Log
$(git log --oneline -10)

## Status
$(git status --short | Out-String)

## Estructura limpia
$(Get-ChildItem -Force | Where-Object { $_.Name -notin @('node_modules','target','dist','.git') } | ForEach-Object { "- $($_.Name)" } | Out-String)

## Tauri Apps
$(Get-ChildItem -Recurse -Depth 3 -Filter "tauri.conf.json" -ErrorAction SilentlyContinue | ForEach-Object { "- $($_.DirectoryName)" } | Out-String)

## Archivos grandes
$(Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 20MB -and $_.FullName -notlike "*\target\*" } | Sort-Object Length -Descending | Select-Object -First 10 FullName, Length | Out-String)
"@
  $report | Set-Content $reportPath -Encoding UTF8
  Write-Host "`nReporte guardado en: $reportPath" -ForegroundColor Green
}

Write-Host "`n== FIN SYNC CHECK ==" -ForegroundColor Green
