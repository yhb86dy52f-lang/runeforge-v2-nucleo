==========================================================

RUNEFORGE V2.0 - DESPLIEGUE OFFLINE-FIRST (PWA)

==========================================================

Este script toma los recursos descargados, los renombra

a los estándares PWA y los despliega en el servidor.

$sourcePath = "C:\RUNEFORGE_V2_CORE\APPLICACION"
$publicPath = "C:\RUNEFORGE_V2_CORE\public"

Write-Host "`n=== [⚒️] DESPLEGANDO ARQUITECTURA PWA OFFLINE-FIRST ===" -ForegroundColor Cyan

1. Crear directorio public si no existe

if (-not (Test-Path $publicPath)) {
New-Item -ItemType Directory -Path $publicPath -Force | Out-Null
Write-Host "[+] Directorio \public creado." -ForegroundColor DarkGray
}

2. Renombrar y mover archivos a la ubicación correcta

Write-Host "[*] Reestructurando y empaquetando archivos web..." -ForegroundColor Yellow

Renombrar HTML

if (Test-Path "$sourcePath\runeforge_pwa_offline_first.html") {
Move-Item -Path "$sourcePath\runeforge_pwa_offline_first.html" -Destination "$publicPath\index.html" -Force
Write-Host "  -> index.html configurado." -ForegroundColor Green
}

Renombrar Manifiesto (Debe ser .json)

if (Test-Path "$sourcePath\MANIFIESTO.txt") {
Move-Item -Path "$sourcePath\MANIFIESTO.txt" -Destination "$publicPath\manifest.json" -Force
Write-Host "  -> manifest.json configurado." -ForegroundColor Green
}

Renombrar Service Worker (Debe ser .js)

if (Test-Path "$sourcePath\service_worker_cach_offline.js") {
Move-Item -Path "$sourcePath\service_worker_cach_offline.js" -Destination "$publicPath\sw.js" -Force
Write-Host "  -> sw.js configurado." -ForegroundColor Green
}

Write-Host "[✓] Todos los recursos consolidados en $publicPath" -ForegroundColor Green

3. Informar al usuario cómo usarlo

Write-Host "n==========================================================" -ForegroundColor Yellow Write-Host " PASOS EN TU IPHONE PARA MODO OFFLINE:" -ForegroundColor Cyan Write-Host " 1. Asegúrate de que tu servidor Fastify esté corriendo." Write-Host " 2. Conéctate al Wi-Fi de tu casa o enciende Tailscale." Write-Host " 3. Abre Safari e ingresa a: http://192.168.X.X:3100/ (Tu IP local)" Write-Host "    (O usa http://100.111.32.10:3100/ si estás en VPN)" Write-Host " 4. Toca el botón 'Compartir' (el cuadrado con la flecha hacia arriba)." Write-Host " 5. Selecciona 'Agregar a inicio' (Add to Home Screen)." Write-Host " 6. ¡Listo! Abre Runeforge desde los iconos de tu iPhone." Write-Host "    Ya puedes apagar el Wi-Fi/Datos y la App seguirá abriendo." Write-Host "==========================================================n" -ForegroundColor Yellow

$msg = "App PWA Offline lista. ¡Procede a instalarla en el iPhone!"
$msg | Set-Clipboard
Write-Host "[✓] Instrucciones copiadas al portapapeles." -ForegroundColor Green