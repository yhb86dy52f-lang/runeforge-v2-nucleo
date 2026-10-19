# modo_autonomo_v2.ps1 - FIX con log visible
param([switch]$Auto)
$ErrorActionPreference="Continue"
try{ Remove-Module PSReadLine -ErrorAction SilentlyContinue }catch{}

$root = $PSScriptRoot
if(-not $root){ $root = (Get-Location).Path }
if($root -like "*\scripts"){ $root = Split-Path $root -Parent }
Set-Location $root

# Transcript para que veas que si jala
$logFile = Join-Path $root "logs\autonomo_$(Get-Date -Format yyyyMMdd_HHmmss).log"
New-Item -ItemType Directory -Force -Path (Split-Path $logFile -Parent) | Out-Null
Start-Transcript -Path $logFile -Append -ErrorAction SilentlyContinue | Out-Null

Write-Host "=== [AUTONOMO V2] ROOT $root Auto=$Auto ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date)" -ForegroundColor DarkGray
Write-Host "PSVersion: $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray

function Move-Safe($src,$dst){
  try{
    $dstFull = Join-Path $root $dst
    $dir = Split-Path $dstFull -Parent
    if(!(Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if(Test-Path $src){
      Move-Item $src $dstFull -Force -ErrorAction Stop
      Write-Host "  DEPLOY OK: $dst <- $(Split-Path $src -Leaf)" -ForegroundColor Green
      return $true
    }
  } catch { Write-Host "  DEPLOY FAIL $dst : $_" -ForegroundColor Red }
  return $false
}

$downloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$inbox = Join-Path $root "knowledge\00_INBOX"
$secure = "C:\RUNEFORGE_BACKUPS\secure"
New-Item -ItemType Directory -Force -Path $secure, $inbox, "C:\RUNEFORGE_BACKUPS\bitacoras" | Out-Null

Write-Host "`n[1] Seguridad - moviendo backup-codes a $secure" -ForegroundColor Yellow
foreach($baseDir in @($downloads, $inbox)){
  Get-ChildItem $baseDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Backup-codes*" -or $_.Name -like "*devices*.csv" } | ForEach-Object {
    try{
      Move-Item $_.FullName (Join-Path $secure $_.Name) -Force
      Write-Host "  SECURE: $($_.Name) -> $secure" -ForegroundColor Red
    } catch { Write-Host "  SECURE FAIL: $_" -ForegroundColor DarkRed }
  }
}

Write-Host "`n[2] Desplegando Hoy (6) de Descargas" -ForegroundColor Yellow
$filesHoy = Get-ChildItem $downloads -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) }
Write-Host "  Encontrados en Descargas ultimas 24h: $($filesHoy.Count)" -ForegroundColor DarkGray
foreach($f in $filesHoy){
  $l = $f.Name.ToLower()
  if($l -like "init-db*.js" -or $l -like "init_db*"){ Move-Safe $f.FullName "scripts\init_db.js" }
  elseif($l -eq "backup.ps1"){ Move-Safe $f.FullName "scripts\backup.ps1" }
  elseif($l -like "*parser*.js"){ Move-Safe $f.FullName "src\backend\services\bitacora_parser.js" }
  elseif($l -like "*schema*.sql"){ Move-Safe $f.FullName "scripts\schema_bitacoras_v2.sql" }
  elseif($l -like "roadmap*critica*"){ Move-Safe $f.FullName "docs\ROADMAP-V2-CRITICA.md" }
}

Write-Host "`n[3] Corrigiendo 00_INBOX mal clasificados" -ForegroundColor Yellow
Get-ChildItem $inbox -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "init|backup|parser|schema" -and $_.Extension -in @(".js",".ps1",".sql") } | ForEach-Object {
  $l = $_.Name.ToLower()
  if($l -like "init*"){ Move-Safe $_.FullName "scripts\init_db.js" }
  elseif($l -like "backup*"){ Move-Safe $_.FullName "scripts\backup.ps1" }
  elseif($l -like "*parser*"){ Move-Safe $_.FullName "src\backend\services\bitacora_parser.js" }
  elseif($l -like "*schema*"){ Move-Safe $_.FullName "scripts\schema_bitacoras_v2.sql" }
}

Write-Host "`n[4] Verificando nucleo" -ForegroundColor Yellow
@("config\llm-profiles.json","src\backend\services\llm\BaseProvider.js","src\backend\services\llm\adapters\ollama.js","src\backend\services\llm\factory.js","scripts\init_db.js","scripts\backup.ps1") | ForEach-Object {
  if(Test-Path $_){ Write-Host "  OK $_" -ForegroundColor Green } else { Write-Host "  FALTA $_" -ForegroundColor Red }
}

Write-Host "`n[5] Init DB" -ForegroundColor Yellow
if(!(Test-Path "data\runeforge.db")){
  if(!(Test-Path "node_modules\better-sqlite3")){
    Write-Host "  Instalando better-sqlite3..." -ForegroundColor DarkYellow
    npm i better-sqlite3 --silent
  }
  try{ node scripts\init_db.js } catch { Write-Host "  init_db fallo: $_" -ForegroundColor Red }
} else { Write-Host "  DB ya existe" -ForegroundColor Green }

Write-Host "`n[6] Backup inmediato" -ForegroundColor Yellow
try{ & (Join-Path $root "scripts\backup.ps1") }catch{ Write-Host "  backup error: $_" -ForegroundColor Red }

Write-Host "`n[7] Launcher" -ForegroundColor Yellow
try{ & (Join-Path $root "scripts\runeforge_launcher.ps1") }catch{ Write-Host "  launcher error: $_" -ForegroundColor Red }

Write-Host "`n=== REPORTE FINAL ===" -ForegroundColor Cyan
Write-Host "Inbox: $((Get-ChildItem $inbox -File -ErrorAction SilentlyContinue | Measure-Object).Count) archivos"
Write-Host "Secure: $((Get-ChildItem $secure -File -ErrorAction SilentlyContinue | Measure-Object).Count) archivos"
Write-Host "Backups: $((Get-ChildItem "C:\RUNEFORGE_BACKUPS\bitacoras" -File -ErrorAction SilentlyContinue | Measure-Object).Count)"
Write-Host "DB size: $((Get-Item "data\runeforge.db" -ErrorAction SilentlyContinue).Length/1KB) KB"
try{
  $oll = Invoke-RestMethod http://127.0.0.1:11434/api/tags -TimeoutSec 2
  Write-Host "Ollama: $($oll.models.Count) modelos"
} catch { Write-Host "Ollama: no responde" -ForegroundColor Red }

Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
Write-Host "`nLog guardado en: $logFile" -ForegroundColor DarkGray
Write-Host "Listo - si ves este mensaje, SI JALO" -ForegroundColor Green
