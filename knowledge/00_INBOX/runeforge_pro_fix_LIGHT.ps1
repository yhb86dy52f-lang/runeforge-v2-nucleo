# RUNEFORGE PRO - FIX LIGHT v2 - RUTA: C:\Users\nesth\Downloads
# Guarda este archivo como: C:\Users\nesth\Downloads\runeforge_pro_fix_LIGHT.ps1
# Ejecutar desde esa carpeta

$projectRoot = "C:\RUNEFOGE_PRO"
$downloadsPath = "C:\Users\nesth\Downloads"
Set-Location $projectRoot

Write-Host "== FIX LIGHT v2 - Proyecto: $projectRoot ==" -ForegroundColor Cyan
Write-Host "Script ubicado en: $downloadsPath" -ForegroundColor DarkGray

# 1. .GITIGNORE
Write-Host "`n[1/3] .gitignore..." -ForegroundColor Green
@"
# RUNEFORGE PRO - GITIGNORE LIGHT - desde Downloads
.env
*.env
**/app.env
*.key
_SAFE_BACKUPS/
_ARCHIVE_DUP_ENV/
_archive/
data/audits/
tools/
node_modules/
**/node_modules/
.n8n/
lab/n8n/runtime/
lab/n8n/runtime_canary_2_20_12/
*.log
"@ | Set-Content "$projectRoot\.gitignore" -Encoding utf8 -Force

# 2. Limpieza git solo pesado
Write-Host "[2/3] Limpieza indice git..." -ForegroundColor Green
$pesadas = @("_SAFE_BACKUPS","_ARCHIVE_DUP_ENV","_archive","app/node_modules","swarm_core/node_modules","lab/n8n/runtime","lab/n8n/runtime_canary_2_20_12","tools")
foreach($p in $pesadas){
  $full = Join-Path $projectRoot $p
  if(Test-Path $full){
    Write-Host "  rm cached: $p" -ForegroundColor DarkGray
    git -C $projectRoot rm -r --cached --quiet "$p" 2>$null
  }
}

# 3. Estado persistente
Write-Host "[3/3] Creando _ESTADO_DIARIO..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "$projectRoot\_ESTADO_DIARIO" | Out-Null
New-Item -ItemType Directory -Force -Path "$projectRoot\docs\jugo" | Out-Null

@"
# ESTADO PERSISTENTE - NO EMPEZAR DE 0
Fecha: $(Get-Date -Format "yyyy-MM-dd HH:mm")
Proyecto: $projectRoot
Script: $downloadsPath\runeforge_pro_fix_LIGHT.ps1

Ya no empiezas de 0. Este README guarda tu avance.

Flujo:
1. git status (debe estar limpio ahora)
2. Trabaja en app/src/modules/ y docs/jugo/
3. git add . ; git commit ; git push

Backups siguen en disco pero fuera de git.
"@ | Set-Content "$projectRoot\_ESTADO_DIARIO\README.md" -Encoding utf8 -Force

Write-Host "`n=== LISTO ===" -ForegroundColor Cyan
git -C $projectRoot status --short | Select-Object -First 40
Write-Host "`nSi ya no ves _SAFE_BACKUPS, ejecuta:" -ForegroundColor Yellow
Write-Host "git -C $projectRoot add .gitignore _ESTADO_DIARIO" -ForegroundColor White
Write-Host "git -C $projectRoot commit -m 'chore: gitignore light'" -ForegroundColor White
Write-Host "git -C $projectRoot push" -ForegroundColor White
