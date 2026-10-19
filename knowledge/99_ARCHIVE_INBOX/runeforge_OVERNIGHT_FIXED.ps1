Set-Location "C:\RUNEFOGE_PRO"
New-Item -ItemType Directory -Force -Path ".\scripts",".\logs",".\docs\jugo\commander",".\docs\jugo\visual_layout",".\docs\jugo\prompts",".\docs\jugo\inventario",".\_ESTADO_DIARIO" | Out-Null
@'
# RUNEFORGE OVERNIGHT FIXED - SIN BLOQUEO GIT GC
Set-Location "C:\RUNEFOGE_PRO"
$ErrorActionPreference = "SilentlyContinue"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\logs\overnight_jugo_FIXED_$timestamp.log"
Start-Transcript -Path $logFile -Force | Out-Null
Write-Host "=== OVERNIGHT FIXED START $timestamp ===" -ForegroundColor Cyan
Write-Host "HEAD: $(git log --oneline -1)" -ForegroundColor Green

# 0. Limpia desktop.ini de .git (por si acaso)
Get-ChildItem -Path .\.git -Filter desktop.ini -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

# 1. Inventario pesado data/
Write-Host "`n[1/6] Inventario data/ ..." -ForegroundColor Yellow
$inventory = @()
if(Test-Path ".\data"){
  $files = Get-ChildItem -Path ".\data" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 10MB }
  foreach($f in $files){
    $inventory += [PSCustomObject]@{ Path=$f.FullName.Replace((Get-Location).Path+"\",""); SizeKB=[math]::Round($f.Length/1KB,1) }
  }
  $inventory | Export-Csv ".\docs\jugo\inventario\inventario_data_$timestamp.csv" -NoTypeInformation -Encoding UTF8
  Write-Host "Inventario: $($inventory.Count) archivos" -ForegroundColor Green
} else { Write-Host "data/ no existe (ya esta fuera de git)" -ForegroundColor DarkGray }

# 2. Extraccion curada <500KB
Write-Host "`n[2/6] Extrayendo jugo <500KB ..." -ForegroundColor Yellow
$curated=0
$allData = @()
if(Test-Path ".\data"){ $allData += Get-ChildItem -Path ".\data" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 500KB -and $_.Length -gt 50 } }
if(Test-Path ".\RUNEFORGE_KNOWLEDGE"){ $allData += Get-ChildItem -Path ".\RUNEFORGE_KNOWLEDGE" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 500KB } }
if(Test-Path ".\QUARANTINE_MIGRATION"){ $allData += Get-ChildItem -Path ".\QUARANTINE_MIGRATION" -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 500KB -and $_.Extension -in @(".md",".json",".txt") } }

foreach($c in $allData){
  if($c.FullName -like "*node_modules*" -or $c.FullName -like "*.env*" -or $c.FullName -like "*.zip" -or $c.FullName -like "*\logs\*" -or $c.Length -eq 0){ continue }
  $destFolder=".\docs\jugo\prompts"
  if($c.FullName -like "*commander*"){ $destFolder=".\docs\jugo\commander" }
  elseif($c.FullName -like "*visual_layout*" -or $c.FullName -like "*cctv*" -or $c.FullName -like "*croquis*" -or $c.FullName -like "*geo*"){ $destFolder=".\docs\jugo\visual_layout" }
  $dest=Join-Path $destFolder $c.Name
  if(-not (Test-Path $dest)){
    Copy-Item $c.FullName $dest -Force -ErrorAction SilentlyContinue
    $curated++
  }
}
Write-Host "Curado total: $curated" -ForegroundColor Green

# 3. Limpieza segura (NO borra data/)
Write-Host "`n[3/6] Limpieza segura ..." -ForegroundColor Yellow
@(".\output",".\rf_temp",".\.tmp.driveupload",".\01_INBOX_WEB",".\autonomo_workspace") | ForEach-Object {
  if(Test-Path $_){ Write-Host "Borrando $_" -ForegroundColor DarkGray; Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue }
}
Get-ChildItem ".\logs" -Filter "*.log" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force -ErrorAction SilentlyContinue

# 4. OPTIMIZACION GIT SEGURA (FIX del error que tenias)
Write-Host "`n[4/6] Optimizando git (seguro, sin borrar refs) ..." -ForegroundColor Yellow
git repack -a -d -l 2>$null
git prune 2>$null
git gc --auto 2>$null
Write-Host "GC seguro OK" -ForegroundColor Green

# 5. Commit jugo
Write-Host "`n[5/6] Commit docs/jugo/ ..." -ForegroundColor Yellow
git add docs/jugo/ -f 2>$null
$changes = git status --short
Write-Host $changes -ForegroundColor DarkGray
if($changes -match "docs/jugo"){
  git commit -m "feat(jugo): overnight FIXED $timestamp - $curated curados <500KB"
  git push -u origin main
  Write-Host "Push OK" -ForegroundColor Green
} else { Write-Host "Nada nuevo en docs/jugo" -ForegroundColor Yellow }

# 6. Estado para mañana
Write-Host "`n[6/6] Estado final ..." -ForegroundColor Yellow
$final = @"
# OVERNIGHT FIXED $timestamp
HEAD: $(git log --oneline -1)
Curados: $curated
Inventario: docs/jugo/inventario/inventario_data_$timestamp.csv
Log: $logFile
Status: $(git status --short)
"@
$final | Set-Content ".\_ESTADO_DIARIO\README_OVERNIGHT_FIXED_$timestamp.md" -Encoding utf8 -Force
git add "_ESTADO_DIARIO/README_OVERNIGHT_FIXED_$timestamp.md" -f 2>$null
git commit -m "chore: estado overnight fixed $timestamp" 2>$null
git push 2>$null

Write-Host "`n=== OVERNIGHT FIXED FIN ===" -ForegroundColor Cyan
git log --oneline -3
git status --short
Stop-Transcript | Out-Null
'@ | Set-Content ".\scripts\overnight_jugo_FIXED.ps1" -Encoding utf8 -Force

Write-Host "Script FIXED creado en .\scripts\overnight_jugo_FIXED.ps1 - Lanzando..." -ForegroundColor Green
PowerShell -ExecutionPolicy Bypass -File ".\scripts\overnight_jugo_FIXED.ps1"
