# modo_autonomo.ps1 - RUNEFORGE MODO AUTONOMO ETAPA 1.5
# Corrige el movimiento de 69 archivos a 00_INBOX y despliega los 6 de Hoy a su sitio correcto
# Uso: pwsh como ADMIN -> .\scripts\modo_autonomo.ps1 -Auto

param([switch]$Auto)

$ErrorActionPreference="Stop"
Remove-Module PSReadLine -ErrorAction SilentlyContinue

$root = $PSScriptRoot
if(-not $root){ $root = (Get-Location).Path }
if($root -like "*\scripts"){ $root = Split-Path $root -Parent }
Set-Location $root

function Write-Utf8NoBom([string]$Path, [string]$Content){
  $dir = Split-Path $Path -Parent
  if($dir -and !(Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText((Join-Path $root $Path), $Content, $utf8)
}
function Move-Safe($src,$dst){
  $dstFull = Join-Path $root $dst
  $dir = Split-Path $dstFull -Parent
  if(!(Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  if(Test-Path $src){
    Move-Item $src $dstFull -Force
    Write-Host "  DEPLOY $dst" -ForegroundColor Green
  }
}

Write-Host "[AUTONOMO] ROOT $root Auto=$Auto" -ForegroundColor Cyan

$downloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$inbox = Join-Path $root "knowledge\00_INBOX"
$secure = "C:\RUNEFORGE_BACKUPS\secure"
New-Item -ItemType Directory -Force -Path $secure, $inbox | Out-Null

# --- 1. CORREGIR SEGURIDAD: sacar Backup-codes y devices csv de inbox/downloads ---
Write-Host "[AUTONOMO] 1. Corrigiendo seguridad..." -ForegroundColor Yellow
$patternsSecure = @("*Backup-codes*","*backup*code*","*forgerrune@gmail.com-devices*","*tailscale*.csv")
foreach($baseDir in @($downloads, $inbox)){
  foreach($pat in $patternsSecure){
    Get-ChildItem $baseDir -File -Filter $pat -ErrorAction SilentlyContinue | ForEach-Object {
      $dest = Join-Path $secure $_.Name
      Move-Item $_.FullName $dest -Force
      Write-Host "  SECURE -> $dest" -ForegroundColor Red
    }
  }
}

# --- 2. MAPEO AUTONOMO de los 6 de Hoy ---
Write-Host "[AUTONOMO] 2. Desplegando recursos de Descargas Hoy (6)..." -ForegroundColor Yellow

# Definir mapeo exacto por nombre (case-insensitive)
$map = @{
  "Init-Db.js" = "scripts\init_db.js"
  "Init-Db (1).js" = "scripts\init_db.js"
  "Init-Db (1).js" = "scripts\init_db.js"
  "backup.ps1" = "scripts\backup.ps1"
  "Bitacora-Parser.js" = "src\backend\services\bitacora_parser.js"
  "Bitacora-Parser.js" = "src\backend\services\bitacora_parser.js"
  "Schema-Bitacoras-V2.sql" = "scripts\schema_bitacoras_v2.sql"
  "ROADMAP-V2-CRITICA.md" = "docs\ROADMAP-V2-CRITICA.md"
}

# Buscar en Downloads los 6 de hoy + variantes con guion bajo
Get-ChildItem $downloads -File | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) } | ForEach-Object {
  $key = $_.Name
  # normalizar
  $lower = $key.ToLower()
  $dst = $null
  if($lower -like "init-db*.js"){ $dst = "scripts\init_db.js" }
  elseif($lower -eq "backup.ps1"){ $dst = "scripts\backup.ps1" }
  elseif($lower -like "bitacora-parser*"){ $dst = "src\backend\services\bitacora_parser.js" }
  elseif($lower -like "schema-bitacoras*"){ $dst = "scripts\schema_bitacoras_v2.sql" }
  elseif($lower -like "roadmap-v2-critica*"){ $dst = "docs\ROADMAP-V2-CRITICA.md" }
  elseif($lower -like "init_db*"){ $dst = "scripts\init_db.js" }

  if($dst){
    # Si el archivo viene de mi generacion, ya es utf8, solo mover
    Move-Safe $_.FullName $dst
  }
}

# Tambien corregir los que el organizador anterior mando a 00_INBOX por error
Get-ChildItem $inbox -File | Where-Object { $_.Extension -in @(".ps1",".js",".sql") -and $_.Name -match "init|backup|parser|schema" } | ForEach-Object {
  $lower = $_.Name.ToLower()
  if($lower -like "init-db*" -or $lower -like "init_db*"){ Move-Safe $_.FullName "scripts\init_db.js" }
  elseif($lower -like "backup*"){ Move-Safe $_.FullName "scripts\backup.ps1" }
  elseif($lower -like "*parser*"){ Move-Safe $_.FullName "src\backend\services\bitacora_parser.js" }
  elseif($lower -like "*schema*"){ Move-Safe $_.FullName "scripts\schema_bitacoras_v2.sql" }
}

# --- 3. Asegurar resto de nucleo Etapa 1 ---
Write-Host "[AUTONOMO] 3. Verificando nucleo..." -ForegroundColor Yellow
$required = @(
  "config\llm-profiles.json",
  "src\backend\services\llm\BaseProvider.js",
  "src\backend\services\llm\adapters\ollama.js",
  "src\backend\services\llm\factory.js",
  "AGENTS.md",
  ".env.template"
)
foreach($r in $required){
  if(!(Test-Path $r)){ Write-Host "  FALTA $r - ejecuta bootstrap_etapa1.ps1" -ForegroundColor Red }
  else { Write-Host "  OK $r" -ForegroundColor DarkGray }
}

# --- 4. Init DB autonomo ---
Write-Host "[AUTONOMO] 4. Init DB..." -ForegroundColor Yellow
if(!(Test-Path "data\runeforge.db")){
  try{
    if(!(Get-Command npm -ErrorAction SilentlyContinue)){ throw "no npm" }
    # instala better-sqlite3 si no existe
    if(!(Test-Path "node_modules\better-sqlite3")){
      Write-Host "  npm i better-sqlite3..." -ForegroundColor DarkYellow
      npm i better-sqlite3 --silent
    }
    node scripts\init_db.js
  } catch {
    Write-Host "  Fallback sqlite3 CLI..." -ForegroundColor DarkYellow
    if(Get-Command sqlite3 -ErrorAction SilentlyContinue){
      sqlite3 data\runeforge.db ".read scripts\schema_bitacoras_v2.sql"
    } else {
      Write-Host "  No hay sqlite3 ni better-sqlite3, DB quedara pendiente" -ForegroundColor Red
    }
  }
} else {
  Write-Host "  DB ya existe: data\runeforge.db" -ForegroundColor Green
}

# --- 5. Backup inmediato ---
Write-Host "[AUTONOMO] 5. Backup inmediato..." -ForegroundColor Yellow
try{ .\scripts\backup.ps1 }catch{ Write-Host "  backup fallo: $_" -ForegroundColor Red }

# --- 6. Tarea 02:00 ---
Write-Host "[AUTONOMO] 6. Tarea programada 02:00..." -ForegroundColor Yellow
try{ .\scripts\setup_backup_task.ps1 }catch{ Write-Host "  tarea requiere ADMIN, omitida" -ForegroundColor DarkYellow }

# --- 7. Launcher check final ---
Write-Host "[AUTONOMO] 7. Launcher final..." -ForegroundColor Yellow
.\scripts\runeforge_launcher.ps1

# --- 8. Reporte ---
Write-Host "`n[AUTONOMO] Reporte final:" -ForegroundColor Cyan
Write-Host "  Inbox: $((Get-ChildItem $inbox -File | Measure-Object).Count) archivos"
Write-Host "  Secure: $((Get-ChildItem $secure -File | Measure-Object).Count) archivos sensibles"
Write-Host "  Backups: $((Get-ChildItem C:\RUNEFORGE_BACKUPS\bitacoras -File -ErrorAction SilentlyContinue | Measure-Object).Count) backups"
Write-Host "  DB: $(if(Test-Path data\runeforge.db){ (Get-Item data\runeforge.db).Length/1KB -as [int] } else { 'NO'}) KB"
Write-Host "  Ollama: $((Invoke-RestMethod http://127.0.0.1:11434/api/tags -TimeoutSec 2).models.Count) modelos"

Write-Host "`n[AUTONOMO] Modo autonomo completado. Etapa 1.5 lista." -ForegroundColor Green
