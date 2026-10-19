#Requires -Version 5.1
# Migrate-Targets.ps1 - Mueve binarios del target global a targets por app

$ErrorActionPreference = 'Stop'
$ROOT = 'C:\RUNEFORGE_V2_CORE'
$REG  = "$ROOT\registry\apps.json"
$GLOB = "$ROOT\target\release"

$r = Get-Content $REG -Raw | ConvertFrom-Json
$moved = 0

foreach($app in $r.apps){
  if(-not $app.src_tauri -or -not (Test-Path $app.src_tauri)){ continue }
  $localTarget = "$($app.src_tauri)\target"
  $localRel    = "$localTarget\release"
  if(-not (Test-Path $localRel)){ New-Item -ItemType Directory -Path $localRel -Force | Out-Null }

  # Candidatos en el target global
  $names = @("$($app.name).exe", "$($app.name -replace '-','_').exe")
  $found = $null
  foreach($n in $names){
    $p = Join-Path $GLOB $n
    if(Test-Path $p){ $found = $p; break }
  }
  if(-not $found){
    # Buscar por similitud
    $found = Get-ChildItem $GLOB -File -Filter '*.exe' -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -match [regex]::Escape($app.name) } |
             Select-Object -First 1 -ExpandProperty FullName
  }

  if($found){
    $dest = Join-Path $localRel (Split-Path $found -Leaf)
    Copy-Item $found $dest -Force
    Write-Host "  [MOVE] $($app.name): $found -> $dest" -ForegroundColor Green
    $app.exe      = $dest
    $app.migrated = $true
    $moved++
  }
}

$r.updated = (Get-Date).ToString('o')
$r | ConvertTo-Json -Depth 8 | Set-Content $REG -Encoding UTF8

Write-Host ""
Write-Host "[OK] Migracion: $moved binarios movidos a targets aislados." -ForegroundColor Cyan
Write-Host "     Registry actualizado: $REG"
Write-Host "     Los originales en $GLOB siguen intactos."