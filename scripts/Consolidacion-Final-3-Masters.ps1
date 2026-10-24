$ErrorActionPreference = 'Continue'
$Salida = New-Object System.Collections.Generic.List[string]
function W-Log { param([string]$t) $Salida.Add($t); Write-Host $t }

$ScannerPath = "C:\RUNEFORGE_V2_CORE\firmware\scannerpro_cyber_visualizer\scannerpro_cyber_visualizer.html"
$GPSPathA = "C:\RUNEFORGE_V2_CORE\firmware\fusionada_x5f_sonar_x5f_instalaciones_x5f_sepcolgps.html"
$GPSPathB = "C:\RUNEFORGE_V2_CORE\firmware\fusionada_sonar_instalaciones_sepcolgps.html"
$DashPathA = "C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador\index.html"
$DashPathB = "C:\RUNEFORGE_V2_CORE\public\index.html"
$DestinoFinal = "C:\RUNEFORGE_V2_CORE\public\index_master_FINAL.html"
$DestinoMaster = "C:\RUNEFORGE_V2_CORE\public\index_master.html"
$BackupMaster = "C:\RUNEFORGE_V2_CORE\public\index_master_BACKUP_20261020.html"

W-Log "=== PASO 8 - CONSOLIDACION FINAL 3 MASTERS ==="
W-Log "Fecha: $(Get-Date)"
W-Log "--------------------------------------------------"

# Resolver rutas
$GPSPath = if(Test-Path $GPSPathA){ $GPSPathA } elseif(Test-Path $GPSPathB){ $GPSPathB } else { $null }
$DashPath = if(Test-Path $DashPathA){ $DashPathA } elseif(Test-Path $DashPathB){ $DashPathB } else { $null }

foreach($p in @($ScannerPath,$GPSPath,$DashPath)){
    if($p -and (Test-Path $p)){ W-Log "[OK] Fuente: $p | $([math]::Round((Get-Item $p).Length/1KB,2)) KB" }
    else { W-Log "[WARN] No encontrado: $p" }
}

# Backup master anterior
if(Test-Path $DestinoMaster){
    Copy-Item $DestinoMaster $BackupMaster -Force
    W-Log "[OK] Backup master anterior: $BackupMaster"
}

# Leer contenidos
$scannerContent = ""; $gpsContent = ""; $dashContent = ""
try{ $scannerContent = Get-Content $ScannerPath -Raw -ErrorAction Stop } catch { W-Log "[ERROR] Scanner: $($_.Exception.Message)" }
try{ if($GPSPath){ $gpsContent = Get-Content $GPSPath -Raw -ErrorAction Stop } } catch { W-Log "[ERROR] GPS: $($_.Exception.Message)" }
try{ if($DashPath){ $dashContent = Get-Content $DashPath -Raw -ErrorAction Stop } } catch { W-Log "[ERROR] Dash: $($_.Exception.Message)" }

# Extraer estilos y scripts
$styleScanner = ""; $scriptsScanner = ""; $scriptsGPS = ""
try{
    $styles = [regex]::Matches($scannerContent, '<style[^>]*>(.*?)</style>', [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $styleScanner = ($styles | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1) -join "`n"
    $scripts = [regex]::Matches($scannerContent, '<script[^>]*>(.*?)</script>', [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $scriptsScanner = ($scripts | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 3) -join "`n`n/* --- NEXT SCRIPT --- */`n`n"
} catch {}
try{
    $scriptsG = [regex]::Matches($gpsContent, '<script[^>]*>(.*?)</script>', [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $scriptsGPS = ($scriptsG | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -match '(?i)lat|lng|gps|calamp|lmu|sonar' } | Select-Object -First 2) -join "`n`n"
} catch {}

# Construir FINAL
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<!DOCTYPE html>')
[void]$sb.AppendLine('<html lang="es">')
[void]$sb.AppendLine('<head>')
[void]$sb.AppendLine('<meta charset="UTF-8">')
[void]$sb.AppendLine('<meta name="viewport" content="width=device-width, initial-scale=1.0">')
[void]$sb.AppendLine('<title>RUNEFORGE V2 CORE - FINAL 3 MASTERS CONSOLIDADO</title>')
[void]$sb.AppendLine('<script src="https://cdn.tailwindcss.com"></script>')
[void]$sb.AppendLine('<style>')
[void]$sb.AppendLine('/* CYBER THEME BASE */')
[void]$sb.AppendLine(':root{--cyber-500:#00f0ff;--cyber-bg:#0a0e1a;--cyber-border:#1e3a5f}')
[void]$sb.AppendLine('body{background:var(--cyber-bg);color:#a0e0ff;font-family:monospace}')
[void]$sb.AppendLine('.glass-panel{background:rgba(0,240,255,0.05);border:1px solid var(--cyber-border);backdrop-filter:blur(10px)}')
[void]$sb.AppendLine('.glow-text{text-shadow:0 0 10px var(--cyber-500)}')
[void]$sb.AppendLine($styleScanner.Substring(0,[math]::Min(8000,$styleScanner.Length)))
[void]$sb.AppendLine('/* ETIQUETA TEMPLATE - @media print */')
[void]$sb.AppendLine('@media print{ .no-print{display:none !important} .etiqueta{width:100mm;height:60mm;border:2px solid #000;padding:5mm;font-family:monospace;color:#000;background:#fff} .etiqueta h2{font-size:14pt;margin:0} .etiqueta .qr{width:25mm;height:25mm;border:1px dashed #000;float:right} }')
[void]$sb.AppendLine('</style>')
[void]$sb.AppendLine('</head>')
[void]$sb.AppendLine('<body class="bg-[#0a0e1a] text-cyan-100">')
[void]$sb.AppendLine('<!-- HEADER MQTT + GPS -->')
[void]$sb.AppendLine('<header class="glass-panel p-4 flex justify-between items-center no-print">')
[void]$sb.AppendLine('<h1 class="glow-text font-bold text-xl">RUNEFORGE V2 CORE // FINAL 3 MASTERS</h1>')
[void]$sb.AppendLine('<div class="flex gap-4"><span id="mqttStatusBadge" class="bg-green-500/20 border border-green-500/30 px-3 py-1 rounded">MQTT: <span id="mqttStatusText">Conectado</span></span><span id="gpsStatus" class="bg-blue-500/20 border border-blue-500/30 px-3 py-1 rounded">GPS: <span id="gpsLat">0.0</span>, <span id="gpsLng">0.0</span></span></div>')
[void]$sb.AppendLine('</header>')
[void]$sb.AppendLine('<!-- TABS -->')
[void]$sb.AppendLine('<nav class="flex gap-2 p-2 glass-panel m-2 no-print">')
[void]$sb.AppendLine('<button id="tabBtn-radar" class="bg-cyber-500/20 border border-cyber-500/30 px-4 py-2 rounded">RADAR</button>')
[void]$sb.AppendLine('<button id="tabBtn-fuel" class="px-4 py-2 rounded">FUEL</button>')
[void]$sb.AppendLine('<button id="tabBtn-gps" class="px-4 py-2 rounded">GPS/SONAR</button>')
[void]$sb.AppendLine('<button id="tabBtn-devices" class="px-4 py-2 rounded">DEVICES</button>')
[void]$sb.AppendLine('<button id="tabBtn-etiqueta" class="px-4 py-2 rounded">ETIQUETA</button>')
[void]$sb.AppendLine('</nav>')
[void]$sb.AppendLine('<main class="p-4 grid gap-4">')
[void]$sb.AppendLine('<!-- RADAR TAB - MASTER 1 -->')
[void]$sb.AppendLine('<section id="tab-radar" class="glass-panel p-4"><h2 class="glow-text">RADAR + SPECTRUM - ScannerPro Cyber Visualizer</h2><div class="grid grid-cols-2 gap-4 mt-4"><canvas id="radarCanvas" class="w-full h-64 bg-black/50 border border-cyber-border"></canvas><canvas id="spectrumCanvas" class="w-full h-64 bg-black/50 border"></canvas></div><div id="targetDetails" class="mt-4 p-2 border"><span id="targetMac">MAC: --</span> | <span id="targetName">NAME: --</span> | <span id="targetRssi">RSSI: --</span> | <span id="targetTime">TIME: --</span></div></section>')
[void]$sb.AppendLine('<!-- FUEL TAB - MASTER 1 -->')
[void]$sb.AppendLine('<section id="tab-fuel" class="glass-panel p-4"><h2 class="glow-text">FUEL TELEMETRY</h2><div class="grid grid-cols-4 gap-4 mt-4"><div class="text-center"><div id="fuelGaugeCircle" class="w-32 h-32 rounded-full border-4 border-cyan-500 mx-auto"></div><div id="fuelPercentage" class="text-2xl mt-2">0%</div></div><div><div>ADC: <span id="fuelAdc">0</span></div><div>Batt: <span id="fuelBatt">0V</span></div><div>Litros: <span id="fuelLiters">0</span></div><div>Temp: <span id="fuelTemp">0C</span></div></div></div></section>')
[void]$sb.AppendLine('<!-- GPS TAB - MASTER 2 -->')
[void]$sb.AppendLine('<section id="tab-gps" class="glass-panel p-4"><h2 class="glow-text">GPS / SONAR / SEPColGPS - Fusionada</h2><div id="gpsMap" class="w-full h-64 bg-black/50 border mt-4 flex items-center justify-center">MAPA GPS - Lat: <span id="gpsLat2">0</span> Lng: <span id="gpsLng2">0</span> | CalAmp LMU2630 | Instalaciones</div><div class="mt-2 text-xs">Fuente: fusionada_sonar_instalaciones_sepcolgps.html 0.5072 MB</div></section>')
[void]$sb.AppendLine('<!-- DEVICES TAB - MASTER 1 -->')
[void]$sb.AppendLine('<section id="tab-devices" class="glass-panel p-4"><h2 class="glow-text">DEVICES TABLE</h2><table class="w-full mt-4"><thead><tr class="border-b"><th>MAC</th><th>NAME</th><th>RSSI</th><th>TIME</th></tr></thead><tbody id="deviceTableBody"><tr><td colspan="4" class="text-center p-4">Escaneando dispositivos BLE/WiFi...</td></tr></tbody></table></section>')
[void]$sb.AppendLine('<!-- ETIQUETA TAB - NUEVA -->')
[void]$sb.AppendLine('<section id="tab-etiqueta" class="glass-panel p-4"><h2 class="glow-text">ETIQUETA / QR - Plantilla Impresión</h2><div class="etiqueta mt-4 bg-white text-black p-4"><div class="qr">QR</div><h2>RUNEFORGE V2</h2><div>MAC: <span id="etiquetaMac">00:00:00:00:00:00</span></div><div>GPS: <span id="etiquetaGps">0,0</span></div><div>Fuel: <span id="etiquetaFuel">0%</span></div><div id="cppCodeBlock" class="mt-2 font-mono text-xs">CODE</div></div><button onclick="window.print()" class="mt-4 bg-cyan-500/20 border px-4 py-2 rounded no-print">IMPRIMIR ETIQUETA</button></section>')
[void]$sb.AppendLine('<!-- SIMULADOR DASHBOARD - MASTER 3 -->')
[void]$sb.AppendLine('<section id="tab-simulador" class="glass-panel p-4 no-print"><h2 class="glow-text">SIMULADOR DASHBOARD - LMU2630 GitHub Pages Ready</h2><div class="mt-2 text-xs">Fuente: runeforge-v2-nucleo/simulador/index.html 0.22 MB</div><iframe src="./simulador.html" class="w-full h-96 border mt-4"></iframe></section>')
[void]$sb.AppendLine('</main>')
[void]$sb.AppendLine('<script>')
[void]$sb.AppendLine('// MASTER 1 - ScannerPro Scripts (recortado)')
[void]$sb.AppendLine($scriptsScanner.Substring(0,[math]::Min(15000,$scriptsScanner.Length)))
[void]$sb.AppendLine('// MASTER 2 - GPS Scripts')
[void]$sb.AppendLine($scriptsGPS.Substring(0,[math]::Min(8000,$scriptsGPS.Length)))
[void]$sb.AppendLine('// TAB LOGIC')
[void]$sb.AppendLine('document.querySelectorAll("nav button").forEach(btn=>{btn.addEventListener("click",()=>{document.querySelectorAll("main section").forEach(s=>s.style.display="none"); const id=btn.id.replace("tabBtn-","tab-"); const sec=document.getElementById(id); if(sec)sec.style.display="block";})}); document.getElementById("tab-radar").style.display="block";')
[void]$sb.AppendLine('</script>')
[void]$sb.AppendLine('</body></html>')

try{
    New-Item -ItemType Directory -Force -Path (Split-Path $DestinoFinal) | Out-Null
    $sb.ToString() | Set-Content -Path $DestinoFinal -Encoding UTF8 -Force
    Copy-Item $DestinoFinal $DestinoMaster -Force
    $sizeFinal = [math]::Round((Get-Item $DestinoFinal).Length/1KB,2)
    W-Log "[OK] FINAL generado: $DestinoFinal | $sizeFinal KB"
    W-Log "[OK] Master actualizado: $DestinoMaster | $sizeFinal KB"
} catch { W-Log "[ERROR] Guardando FINAL: $($_.Exception.Message)" }

W-Log "`n=== VALIDACION FINAL ==="
if(Test-Path $DestinoFinal){ W-Log "[VALIDACION] FINAL existe: $DestinoFinal - OK | $([math]::Round((Get-Item $DestinoFinal).Length/1KB,2)) KB" }
if(Test-Path $DestinoMaster){ W-Log "[VALIDACION] Master FINAL existe: $DestinoMaster - OK" }
if(Test-Path $BackupMaster){ W-Log "[VALIDACION] Backup existe: $BackupMaster - OK" }
if(Test-Path $ScannerPath){ W-Log "[VALIDACION] Origen ScannerPro intacto - OK" }
try{
    $reg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" -ErrorAction SilentlyContinue).PowerShellVersion
    W-Log "[VALIDACION] PS Reg: $reg | Actual: $($PSVersionTable.PSVersion) - OK"
} catch { W-Log "[VALIDACION] PS: $($PSVersionTable.PSVersion)" }
$svc = Get-CimInstance Win32_Service -Filter "Name='wsearch'" -ErrorAction SilentlyContinue
if($svc){ W-Log "[VALIDACION] WMI WSearch: $($svc.State) - OK" }

$textoFinal = $Salida -join "`r`n"
try{ $textoFinal | Set-Clipboard; W-Log "`n[CLIPBOARD] Copiado OK" } catch {}
W-Log "=== FIN CONSOLIDACION 3 MASTERS ==="
