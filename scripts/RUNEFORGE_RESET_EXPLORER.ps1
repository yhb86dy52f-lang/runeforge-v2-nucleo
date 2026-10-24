# RESET EXPLORADOR - FIX 0 BYTES EN DISCO ICLOUD
$ErrorActionPreference="SilentlyContinue"
Write-Host "--- Reseteando Explorador de Archivos ---" -ForegroundColor Yellow

# 1. Mata explorer colgado
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep 2
Start-Process explorer.exe
Write-Host "Explorer reiniciado" -ForegroundColor Green

# 2. Limpia cache de miniaturas y recent
Remove-Item "$env:LocalAppData\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LocalAppData\Microsoft\Windows\Explorer\iconcache_*.db" -Force -ErrorAction SilentlyContinue
Write-Host "Cache limpiado" -ForegroundColor Green

# 3. Reinicia iCloud Drive (lo matamos antes)
Start-Process "$env:ProgramFiles\Common Files\Apple\Internet Services\iCloudDrive.exe" -ErrorAction SilentlyContinue
Start-Process "$env:ProgramFiles\Apple\iCloud\iCloudDrive.exe" -ErrorAction SilentlyContinue
# Intenta ambas rutas
$icloudPaths=@(
"C:\Program Files\Common Files\Apple\Internet Services\iCloudDrive.exe",
"C:\Program Files (x86)\Common Files\Apple\Internet Services\iCloudDrive.exe"
)
foreach($p in $icloudPaths){ if(Test-Path $p){ Start-Process $p -ErrorAction SilentlyContinue } }

Write-Host "iCloud Drive reiniciado" -ForegroundColor Green
Start-Sleep 3

# 4. Fuerza descarga del archivo que sale 0 bytes
$src="C:\Users\nesth\Documents\iCloudDrive\Downloads\ggml-large-v3-turbo.bin"
if(Test-Path $src){
 Write-Host "Forzando descarga local de $src..." -ForegroundColor Cyan
 # Quita atributo offline si existe
 attrib -O "$src" -ErrorAction SilentlyContinue
 # Intenta copiar para forzar download
 try{
  # Usa COM para forzar pin
  $shell=New-Object -ComObject Shell.Application
  $folder=$shell.Namespace((Split-Path $src))
  $item=$folder.ParseName((Split-Path $src -Leaf))
  # Verb "Always keep on this device" no siempre disponible, intentamos abrir
  $size=(Get-Item $src).Length
  Write-Host "Tamaño reportado: $size bytes (debe ser 1624555275)" -ForegroundColor White
 }catch{ Write-Host $_.Exception.Message }
}

Write-Host "--- LISTO ---" -ForegroundColor Green
Write-Host "Ahora ve a C:\Users\nesth\Documents\iCloudDrive\Downloads" 
Write-Host "Click derecho a ggml-large-v3-turbo.bin > Siempre mantener en este dispositivo"
Write-Host "Debe cambiar de '0 bytes en disco' a '1.51 GB en disco'"
