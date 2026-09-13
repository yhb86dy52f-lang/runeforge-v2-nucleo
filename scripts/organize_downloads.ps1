# organize_downloads.ps1 - Higiene Etapa 1 v2
# Mueve Downloads a knowledge/00_INBOX sin perder nada, deduplica por hash

$ErrorActionPreference="SilentlyContinue"
Remove-Module PSReadLine -ErrorAction SilentlyContinue

$root = $PSScriptRoot
if(-not $root){ $root = (Get-Location).Path }
if($root -like "*\scripts"){ $root = Split-Path $root -Parent }
Set-Location $root

$downloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
$inbox = Join-Path $root "knowledge\00_INBOX"
$whatsapp_raw = Join-Path $root "knowledge\00_INBOX\whatsapp_raw"
$inventory = Join-Path $root "docs\jugo\inventario"

New-Item -ItemType Directory -Force -Path $inbox, $whatsapp_raw, $inventory | Out-Null

Write-Host "[ORGANIZER] Downloads: $downloads -> $inbox" -ForegroundColor Cyan

# Evitar node_modules, zips gigantes, .tmp
$excludes = @("*.tmp","*.crdownload","desktop.ini","node_modules*")
$files = Get-ChildItem $downloads -File | Where-Object { $_.Name -notin $excludes -and $_.Length -gt 0 -and $_.LastWriteTime -gt (Get-Date).AddDays(-30) }

$hashTable = @{}
if(Test-Path "$inventory\hashes.json"){
  try{ $hashTable = Get-Content "$inventory\hashes.json" -Raw | ConvertFrom-Json -AsHashtable }catch{ $hashTable = @{} }
}

$moved = 0
$dup = 0
$log = @()

foreach($f in $files){
  # Calcula hash rapido
  $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.Substring(0,16)
  if($hashTable.ContainsKey($hash)){
    $dup++
    $log += [PSCustomObject]@{ fecha=Get-Date -Format o; archivo=$f.Name; hash=$hash; estado="duplicado"; origen=$f.FullName; destino=$hashTable[$hash] }
    continue
  }
  $dest = Join-Path $inbox $f.Name
  # Si ya existe, renombra con fecha
  if(Test-Path $dest){
    $base = [IO.Path]::GetFileNameWithoutExtension($f.Name)
    $ext = [IO.Path]::GetExtension($f.Name)
    $dest = Join-Path $inbox "$base`_$(Get-Date -Format yyyyMMdd_HHmmss)$ext"
  }
  try{
    Move-Item $f.FullName $dest -Force
    $hashTable[$hash] = $dest
    $moved++
    $log += [PSCustomObject]@{ fecha=Get-Date -Format o; archivo=$f.Name; hash=$hash; estado="movido"; origen=$f.FullName; destino=$dest }
    Write-Host "  + $($f.Name) -> inbox" -ForegroundColor Green
  } catch {
    Write-Host "  ! fallo $($f.Name): $_" -ForegroundColor Red
  }
}

# Guarda inventario
$log | Export-Csv "$inventory\inventario_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation -Encoding UTF8
$hashTable | ConvertTo-Json | Set-Content "$inventory\hashes.json" -Encoding utf8NoBOM

Write-Host "`n[ORGANIZER] Movidos: $moved Duplicados: $dup Total escaneados: $($files.Count)" -ForegroundColor Cyan
Write-Host "Inventario: docs\jugo\inventario\inventario_$(Get-Date -Format yyyyMMdd).csv" -ForegroundColor DarkGray

# Limpieza bitacoras raw
$bitacoras = Get-ChildItem "data\raw\bitacoras" -ErrorAction SilentlyContinue | Measure-Object | Select-Object -ExpandProperty Count
Write-Host "Bitacoras en data\raw\bitacoras: $bitacoras" -ForegroundColor Yellow
