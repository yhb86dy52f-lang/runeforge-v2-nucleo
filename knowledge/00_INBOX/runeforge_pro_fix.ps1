# RUNEFORGE PRO - FIX DEFINITIVO - No mas empezar de 0
# Ejecutar UNA VEZ como Admin en C:\RUNEFOGE_PRO

Set-Location "C:\RUNEFOGE_PRO"
$ErrorActionPreference = "SilentlyContinue"
$fecha = Get-Date -Format "yyyyMMdd_HHmmss"
$backupRoot = "C:\RUNEFORGE_BACKUPS\$fecha"
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

Write-Host "== RUNEFORGE PRO - NORMALIZACION DEFINITIVA ==" -ForegroundColor Cyan
Write-Host "Backup destino: $backupRoot" -ForegroundColor Yellow

# 1. MOVER BASURA FUERA DEL CORE (no borrar, mover)
Write-Host "`n[1/6] Moviendo backups anidados fuera..." -ForegroundColor Green
$toMove = @("_SAFE_BACKUPS","_ARCHIVE_DUP_ENV","_archive","_ARCHIVE_DUP_ENV")
foreach($d in $toMove){
  if(Test-Path ".\$d"){
    Move-Item ".\$d" "$backupRoot\$d" -Force
    Write-Host " -> Movido $d" -ForegroundColor Gray
  }
}
# Mover runtimes pesados de n8n que no deben estar en git
if(Test-Path ".\lab\n8n\runtime"){ Move-Item ".\lab\n8n\runtime" "$backupRoot\n8n_runtime" -Force }
if(Test-Path ".\lab\n8n\runtime_canary_2_20_12"){ Move-Item ".\lab\n8n\runtime_canary_2_20_12" "$backupRoot\n8n_runtime_canary" -Force }
if(Test-Path ".\tools"){ Move-Item ".\tools" "$backupRoot\tools" -Force }

# 2. .GITIGNORE DEFINITIVO PRO
Write-Host "`n[2/6] Escribiendo .gitignore PRO definitivo..." -ForegroundColor Green
@"
# === RUNEFORGE PRO - GITIGNORE DEFINITIVO ===
# Secrets
.env
*.env
**/app.env
**/*.key
**/termius_key*
**/*ssh_config*
**/OpenSSH-Win64/

# Backups - NUNCA en git
_SAFE_BACKUPS/
_ARCHIVE_DUP_ENV/
_archive/
C:/RUNEFORGE_BACKUPS/
data/audits/
**/backup_*/
**/runtime/
**/runtime_canary*/

# Dependencias
node_modules/
**/node_modules/
.pnp/
.pnp.js
tools/
.n8n/

# Logs y OS
*.log
*.tmp
Thumbs.db
.DS_Store
dist/
build/
"@ | Set-Content .\.gitignore -Encoding UTF8 -Force

# 3. LIMPIAR INDICE GIT
Write-Host "`n[3/6] Limpiando indice git..." -ForegroundColor Green
git rm -r --cached _SAFE_BACKUPS _ARCHIVE_DUP_ENV _archive 2>$null
git rm -r --cached app/node_modules swarm_core/node_modules 2>$null
git rm -r --cached lab/n8n/runtime lab/n8n/runtime_canary_2_20_12 tools 2>$null
git rm --cached src/backend/app.env app/src/backend/app.env 2>$null
git rm --cached --quiet -r --cached . 2>$null
git add .  # re-add con nuevo gitignore

# 4. CREAR ESTRUCTURA CANONICA PARA JUGO
Write-Host "`n[4/6] Creando estructura canonica jugosa..." -ForegroundColor Green
$jugosa = @(
  "docs\jugo",
  "docs\jugo\botforce",
  "docs\jugo\commander",
  "docs\jugo\visual_layout",
  "docs\jugo\security",
  "docs\hardening",
  "data\prompts\canonicos",
  "data\memory\index",
  "_ESTADO_DIARIO"
)
foreach($p in $jugosa){ New-Item -ItemType Directory -Path ".\$p" -Force | Out-Null }

# 5. EXTRAER LO JUGOSO AUTOMATICO
Write-Host "`n[5/6] Extrayendo lo jugoso de cada ruta..." -ForegroundColor Green
# Templates visuales
if(Test-Path ".\data\visual_layout_engine\templates"){
  Copy-Item ".\data\visual_layout_engine\templates\*" ".\docs\jugo\visual_layout\" -Recurse -Force
}
if(Test-Path ".\app\data\visual_layout_engine\templates"){
  Copy-Item ".\app\data\visual_layout_engine\templates\*" ".\docs\jugo\visual_layout\" -Recurse -Force
}
# Security lessons
if(Test-Path ".\data\audits"){
  Get-ChildItem ".\data\audits\security_*" -Directory | Select-Object -First 10 | ForEach-Object {
    $_.Name | Out-File ".\docs\hardening\inventario_seguridad.txt" -Append
  }
}
# Commander y botforce
if(Test-Path ".\data\commander\snippets"){ Copy-Item ".\data\commander\snippets\*" ".\docs\jugo\commander\" -Recurse -Force -ErrorAction SilentlyContinue }
if(Test-Path ".\data\botforce\notes"){ Copy-Item ".\data\botforce\notes\*" ".\docs\jugo\botforce\" -Recurse -Force -ErrorAction SilentlyContinue }

# 6. ESTADO PERSISTENTE - PARA NO EMPEZAR DE 0
Write-Host "`n[6/6] Creando ESTADO PERSISTENTE..." -ForegroundColor Green
@"
# RUNEFORGE PRO - ESTADO PERSISTENTE
# Este archivo evita empezar de 0 cada dia

Fecha normalizacion: $fecha
Root canonico: C:\RUNEFOGE_PRO (sugerido renombrar a C:\RUNEFORGE_PRO)
Backup de limpieza: $backupRoot

## Estructura canonica activa:
- app/src/modules/ -> 12 modulos (beacon, botforce, chat, codex, forge, global_chat, integrations, local_ai, relay, sentinel, trace, webcommand)
- app/src/core/ + shared + adapters
- data/prompts/ + data/memory/
- docs/jugo/ -> aqui va lo jugoso extraido
- scripts/backend, memory, mobile, visual_layout_engine

## Flujo diario (no empezar de 0):
1. git pull
2. .\runeforge_daily.ps1 (te muestra que falta)
3. Trabajar solo en docs/jugo/ o app/src/modules/
4. git add docs/jugo/ app/src/ ; git commit -m "feat: avance jugoso X"
5. git push

## Lo que ya NO esta en git (movido a $backupRoot):
- _SAFE_BACKUPS (3 copias anidadas)
- _archive / _ARCHIVE_DUP_ENV
- node_modules gigantes (openai, langchain, n8n)
- runtimes de lab/n8n

Proximo paso: renombrar C:\RUNEFOGE_PRO a C:\RUNEFORGE_PRO y hacer push inicial limpio.
"@ | Set-Content ".\_ESTADO_DIARIO\README.md" -Encoding UTF8

@"
# Daily launcher - no empezar de 0
Set-Location "C:\RUNEFOGE_PRO"
Write-Host "== RUNEFORGE PRO - STATUS DIARIO ==" -ForegroundColor Cyan
git status --short
Write-Host "`n== JUGO EXTRAIDO ==" -ForegroundColor Green
Get-ChildItem .\docs\jugo -Recurse -File | Measure-Object | Select-Object Count
Write-Host "`n== PENDIENTE POR COMMIT ==" -ForegroundColor Yellow
git diff --name-only
"@ | Set-Content ".\runeforge_daily.ps1" -Encoding UTF8

Write-Host "`n=== LISTO ===" -ForegroundColor Cyan
Write-Host "Backup en: $backupRoot" -ForegroundColor Yellow
Write-Host "Ahora ejecuta:" -ForegroundColor White
Write-Host " git status" 
Write-Host " git add .gitignore _ESTADO_DIARIO docs/jugo app/src"
Write-Host " git commit -m 'chore: normalizacion definitiva PRO - fin de empezar de 0'"
Write-Host " git push"

"Fix PRO completo" | Set-Clipboard
