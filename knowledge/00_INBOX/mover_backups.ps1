# MOVER BACKUPS - RUTA: C:\Users\nesth\Downloads
# Guarda como: C:\Users\nesth\Downloads\mover_backups.ps1
# Ejecutar DESPUES del fix light

$projectRoot = "C:\RUNEFOGE_PRO"
$downloadsPath = "C:\Users\nesth\Downloads"
$dest = "C:\RUNEFORGE_BACKUPS\$(Get-Date -Format yyyyMMdd_HHmmss)"

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Write-Host "Origen: $projectRoot" -ForegroundColor Gray
Write-Host "Destino backups: $dest" -ForegroundColor Yellow
Write-Host "Script desde: $downloadsPath" -ForegroundColor DarkGray

# Robocopy no colapsa terminal
if(Test-Path "$projectRoot\_SAFE_BACKUPS"){
  Write-Host "`nMoviendo _SAFE_BACKUPS con robocopy (2-5 min)..." -ForegroundColor Cyan
  robocopy "$projectRoot\_SAFE_BACKUPS" "$dest\_SAFE_BACKUPS" /E /MOVE /NFL /NDL /NJH /NJS /R:0 /W:0
}

foreach($d in @("_ARCHIVE_DUP_ENV","_archive")){
  $src = Join-Path $projectRoot $d
  if(Test-Path $src){
    Write-Host "Moviendo $d..." -ForegroundColor Cyan
    Move-Item $src $dest -Force
  }
}

Write-Host "`nBackups fuera. Tree ahora sera corto." -ForegroundColor Green
Get-ChildItem $projectRoot -Directory | Select-Object Name
