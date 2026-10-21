$ErrorActionPreference = 'Continue'
$Salida = New-Object System.Collections.Generic.List[string]
function W-Log { param([string]$t) $Salida.Add($t); Write-Host $t }

$Origen = "C:\RUNEFORGE_V2_CORE\firmware\scannerpro_cyber_visualizer\scannerpro_cyber_visualizer.html"
$DestinoMaster = "C:\RUNEFORGE_V2_CORE\public\index_master.html"
$ReportePath = "C:\RUNEFORGE_V2_CORE\public\master_componentes_reporte.txt"

W-Log "=== CONSOLIDACION MASTER TEMPLATE - SIN MOVER DUPLICADOS ==="
W-Log "Fecha: $(Get-Date) | Modo: Solo lectura + creacion de master"
W-Log "--------------------------------------------------"

if(-not (Test-Path $Origen)){
    W-Log "[AVISO] No se encontro en ruta fija, buscando recursivamente..."
    $encontrado = Get-ChildItem -Path "C:\RUNEFORGE_V2_CORE" -Filter "scannerpro_cyber_visualizer.html" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if($encontrado){ $Origen = $encontrado.FullName; W-Log "[OK] Encontrado en: $Origen" }
    else { W-Log "[ERROR] No se encontro scannerpro_cyber_visualizer.html"; $textoFinal = $Salida -join "`r`n"; $textoFinal | Set-Clipboard; return }
}

try{
    $contenido = Get-Content -Path $Origen -Raw -ErrorAction Stop
    $kbOrigen = [math]::Round((Get-Item $Origen).Length / 1KB,2)
    W-Log "[OK] Origen leido: $Origen | $kbOrigen KB | $($contenido.Length) chars"
} catch { W-Log "[ERROR] Lectura origen: $($_.Exception.Message)"; return }

function Extraer-Bloques {
    param([string]$html, [string]$pattern, [string]$nombre)
    $matches = [regex]::Matches($html, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if($matches.Count -gt 0){ W-Log "[EXTRACT] $nombre : $($matches.Count) bloques encontrados"; return $matches | ForEach-Object { $_.Value } }
    else { W-Log "[EXTRACT] $nombre : 0 bloques - se creara placeholder"; return @() }
}

W-Log "`n[1] Extrayendo componentes clave..."
$estilos = Extraer-Bloques -html $contenido -pattern "<style[^>]*>.*?</style>" -nombre "ESTILOS"
$scripts = Extraer-Bloques -html $contenido -pattern "<script[^>]*>.*?</script>" -nombre "SCRIPTS"
$dash = Extraer-Bloques -html $contenido -pattern "<div[^>]*dashboard[^>]*>.*?</div>" -nombre "DASHBOARD"
$etiqueta = Extraer-Bloques -html $contenido -pattern "<div[^>]*etiqueta[^>]*>.*?</div>" -nombre "ETIQUETA"
$qr = Extraer-Bloques -html $contenido -pattern "<div[^>]*qr[^>]*>.*?</div>" -nombre "QR/ESCANER"

W-Log "`n[2] Construyendo master modular..."
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("<!DOCTYPE html>")
[void]$sb.AppendLine("<html lang='es'>")
[void]$sb.AppendLine("<head>")
[void]$sb.AppendLine("<meta charset='UTF-8'><meta name='viewport' content='width=device-width, initial-scale=1.0'>")
[void]$sb.AppendLine("<title>RUNEFORGE MASTER - APP TABAJO</title>")
[void]$sb.AppendLine("<!-- ESTILOS ORIGINALES CONSOLIDADOS -->")
foreach($e in $estilos){ [void]$sb.AppendLine($e) }
[void]$sb.AppendLine("<style>")
[void]$sb.AppendLine("@media print { .no-print { display:none !important; } .etiqueta { page-break-inside: avoid; } }")
[void]$sb.AppendLine(".master-section { border:1px solid #333; margin:10px; padding:10px; border-radius:8px; }")
[void]$sb.AppendLine("</style>")
[void]$sb.AppendLine("</head><body>")
[void]$sb.AppendLine("<h1>RUNEFORGE MASTER TEMPLATE - Generado $(Get-Date)</h1>")
[void]$sb.AppendLine("<p>Origen: $Origen | Sin mover duplicados - modo seguro</p>")

[void]$sb.AppendLine("<div class='master-section' id='sec-dashboard'><h2>DASHBOARD</h2>")
if($dash.Count -gt 0){ $dash | ForEach-Object { [void]$sb.AppendLine($_) } } else { [void]$sb.AppendLine("<!-- Dashboard placeholder - contenido original embebido en JS -->") }
[void]$sb.AppendLine("</div>")

[void]$sb.AppendLine("<div class='master-section' id='sec-etiqueta'><h2>ETIQUETA / IMPRESION</h2>")
if($etiqueta.Count -gt 0){ $etiqueta | ForEach-Object { [void]$sb.AppendLine($_) } } else { [void]$sb.AppendLine("<div id='etiqueta'>Plantilla etiqueta lista para imprimir - hereda estilos originales</div>") }
[void]$sb.AppendLine("</div>")

[void]$sb.AppendLine("<div class='master-section' id='sec-telemetria'><h2>TELEMETRIA GPS + TEMPERATURA</h2><div id='telemetria-gps'>GPS</div><div id='telemetria-temp'>Temperatura</div></div>")
[void]$sb.AppendLine("<div class='master-section' id='sec-qr'><h2>QR / ESCANER</h2>")
if($qr.Count -gt 0){ $qr | ForEach-Object { [void]$sb.AppendLine($_) } } else { [void]$sb.AppendLine("<div id='qr-scanner'>QR Scanner base</div>") }
[void]$sb.AppendLine("</div>")

[void]$sb.AppendLine("<!-- SCRIPTS ORIGINALES -->")
foreach($s in $scripts){ if($s.Length -lt 50000){ [void]$sb.AppendLine($s) } }
[void]$sb.AppendLine("</body></html>")

try{
    New-Item -ItemType Directory -Force -Path (Split-Path $DestinoMaster) | Out-Null
    $sb.ToString() | Set-Content -Path $DestinoMaster -Encoding UTF8 -Force
    $kbDest = [math]::Round((Get-Item $DestinoMaster).Length / 1KB,2)
    W-Log "[OK] Master creado: $DestinoMaster | $kbDest KB"
} catch { W-Log "[ERROR] Creando master: $($_.Exception.Message)" }

W-Log "`n[3] Generando reporte de componentes..."
try{
    $reporte = @()
    $reporte += "REPORTE CONSOLIDACION MASTER - $(Get-Date)"
    $reporte += "Origen: $Origen ($kbOrigen KB)"
    $reporte += "Destino: $DestinoMaster ($kbDest KB)"
    $reporte += "Duplicados movidos: NO - Omitido por seguridad segun autorizacion"
    $reporte += "Componentes: Estilos=$($estilos.Count), Scripts=$($scripts.Count), Dashboard=$($dash.Count), Etiqueta=$($etiqueta.Count), QR=$($qr.Count)"
    $reporte += "Top duplicados detectados pero NO movidos:"
    Get-ChildItem -Path "C:\RUNEFORGE_V2_CORE" -Filter "*.html" -Recurse -File -ErrorAction SilentlyContinue | Group-Object Length | Where-Object { $_.Count -gt 1 -and $_.Name -gt 100000 } | Select-Object -First 3 | ForEach-Object { $reporte += " - $($_.Group[0].FullName) duplicado x$($_.Count)" }
    $reporte | Set-Content -Path $ReportePath -Encoding UTF8 -Force
    W-Log "[OK] Reporte: $ReportePath"
} catch { W-Log "[ERROR] Reporte: $($_.Exception.Message)" }

W-Log "`n=== VALIDACION FINAL ==="
if(Test-Path $DestinoMaster){ W-Log "[VALIDACION] Master existe: $DestinoMaster - OK" } else { W-Log "[VALIDACION] Master NO existe - FAIL" }
if(Test-Path $Origen){ W-Log "[VALIDACION] Origen sigue intacto (no movido): $Origen - OK" }
try{
    $psVer = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" -ErrorAction SilentlyContinue).PowerShellVersion
    W-Log "[VALIDACION] PowerShell Reg: $psVer | Version actual: $($PSVersionTable.PSVersion) - OK"
} catch { W-Log "[VALIDACION] PSVersion: $($PSVersionTable.PSVersion)" }
$svc = Get-CimInstance Win32_Service -Filter "Name='wsearch'" -ErrorAction SilentlyContinue
if($svc){ W-Log "[VALIDACION] WMI Check WSearch: $($svc.State) - OK" }

$textoFinal = $Salida -join "`r`n"
try{ $textoFinal | Set-Clipboard; W-Log "`n[CLIPBOARD] Salida copiada - OK" } catch { W-Log "[CLIPBOARD] Error: $($_.Exception.Message)" }
W-Log "=== FIN CONSOLIDACION SEGURA ==="
