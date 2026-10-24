$ErrorActionPreference = 'Continue'
$Salida = New-Object System.Collections.Generic.List[string]
function W-Log { param([string]$t) $Salida.Add($t); Write-Host $t }

$Origen = "C:\RUNEFORGE_V2_CORE\firmware\scannerpro_cyber_visualizer.html"
$Master = "C:\RUNEFORGE_V2_CORE\public\index_master.html"

W-Log "=== DEEP INSPECTOR VISUALIZER - PASO 3 ==="
W-Log "Fecha: $(Get-Date) | Modo: Solo lectura"
W-Log "--------------------------------------------------"

if(-not (Test-Path $Origen)){
    $f = Get-ChildItem -Path "C:\RUNEFORGE_V2_CORE" -Filter "scannerpro_cyber_visualizer.html" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if($f){ $Origen = $f.FullName; W-Log "[OK] Origen encontrado: $Origen" }
    else { W-Log "[ERROR] No se encontro visualizer"; $textoFinal = $Salida -join "`r`n"; $textoFinal | Set-Clipboard; return }
}

try{
    $contenido = Get-Content -Path $Origen -Raw -ErrorAction Stop
    $sizeKB = [math]::Round((Get-Item $Origen).Length/1KB,2)
    W-Log "[OK] Archivo: $Origen | $sizeKB KB | $($contenido.Length) chars"
} catch { W-Log "[ERROR] Lectura: $($_.Exception.Message)"; return }

W-Log "`n[1] IDs REALES (no suposiciones)"
try{
    $ids = [regex]::Matches($contenido, 'id\s*=\s*["'']([^"'']+)["'']', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    W-Log "Total IDs unicos: $($ids.Count)"
    $ids | Select-Object -First 50 | ForEach-Object { W-Log " - ID: $_" }
    if($ids.Count -gt 50){ W-Log " ... y $($ids.Count - 50) mas (ver reporte completo en clipboard)" }
} catch { W-Log "[ERROR] IDs: $($_.Exception.Message)" }

W-Log "`n[2] CLASES REALES"
try{
    $clasesRaw = [regex]::Matches($contenido, 'class\s*=\s*["'']([^"'']+)["'']', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { $_.Groups[1].Value }
    $clases = $clasesRaw -join " " -split "\s+" | Where-Object { $_ -ne "" } | Sort-Object -Unique
    W-Log "Total clases unicas: $($clases.Count)"
    $clases | Select-Object -First 60 | ForEach-Object { W-Log " - CLASS: $_" }
} catch { W-Log "[ERROR] Clases: $($_.Exception.Message)" }

W-Log "`n[3] BLOQUES @media print - PLANTILLA ETIQUETA"
try{
    $styleBlocks = [regex]::Matches($contenido, '<style[^>]*>(.*?)</style>', [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    W-Log "Style blocks encontrados: $($styleBlocks.Count)"
    $printFound = 0
    foreach($st in $styleBlocks){
        $inner = $st.Groups[1].Value
        if($inner -match '@media\s+print'){
            $printFound++
            W-Log "[PRINT] Bloque #$printFound contiene @media print"
            $snippet = $inner.Substring(0, [math]::Min(1200, $inner.Length))
            W-Log $snippet
            W-Log "--- FIN snippet print #$printFound ---"
        }
    }
    if($printFound -eq 0){
        W-Log "[PRINT] No hay @media print en este archivo. Buscando palabras clave etiqueta/imprimir..."
        $etqMatches = [regex]::Matches($contenido, '.{0,80}etiqueta.{0,80}', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | Select-Object -First 5
        $etqMatches | ForEach-Object { W-Log " - Contexto etiqueta: $($_.Value.Trim())" }
    }
} catch { W-Log "[ERROR] Print: $($_.Exception.Message)" }

W-Log "`n[4] ANALISIS DE LOS 5 SCRIPTS - DONDE ESTA TELEMETRIA"
try{
    $scriptBlocks = [regex]::Matches($contenido, '<script[^>]*>(.*?)</script>', [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    W-Log "Total script blocks: $($scriptBlocks.Count)"
    $idx=1
    foreach($sb in $scriptBlocks){
        $code = $sb.Groups[1].Value
        $len = $code.Length
        $lineas = ($code -split "`n").Count
        $hasGPS = $code -match '(?i)gps|latitud|longitud|\blat\b|\blng\b|calamp|lmu2630|coordenada|sonar|instalaciones'
        $hasTemp = $code -match '(?i)thermo|temperatura|temp|sensor.*temp|CT-Thermo'
        $hasQR = $code -match '(?i)qr|qrcode|scanner|escaner'
        $hasEtiqueta = $code -match '(?i)etiqueta|label.*print|imprimir|ticket'
        $hasDashboard = $code -match '(?i)dashboard|visualizer|grimorio'
        W-Log (" Script #{0}: {1} chars | {2} lineas | GPS:{3} TEMP:{4} QR:{5} ETIQUETA:{6} DASH:{7}" -f $idx, $len, $lineas, $hasGPS, $hasTemp, $hasQR, $hasEtiqueta, $hasDashboard)
        if($hasGPS -or $hasTemp){ 
            $preview = [regex]::Match($code, '.{0,60}(gps|thermo|temperatura|calamp).{0,60}', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if($preview.Success){ W-Log "   -> Preview: $($preview.Value.Trim().Substring(0,[math]::Min(150,$preview.Value.Length)))" }
        }
        $idx++
    }
} catch { W-Log "[ERROR] Scripts: $($_.Exception.Message)" }

W-Log "[STRIPPED 370 bytes]n=== VALIDACION FINAL ==="
if(Test-Path $Origen){ W-Log "[VALIDACION] Origen intacto: $Origen - OK" }
if(Test-Path $Master){ W-Log "[VALIDACION] Master previo existe: $Master - OK" } else { W-Log "[VALIDACION] Master previo no existe aun - INFO" }
try{
    $reg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" -ErrorAction SilentlyContinue).PowerShellVersion
    W-Log "[VALIDACION] PS Reg: $reg | Actual: $($PSVersionTable.PSVersion) - OK"
} catch { W-Log "[VALIDACION] PS: $($PSVersionTable.PSVersion)" }
$svc = Get-CimInstance Win32_Service -Filter "Name='wsearch'" -ErrorAction SilentlyContinue
if($svc){ W-Log "[VALIDACION] WMI WSearch: $($svc.State) - OK" }

$textoFinal = $Salida -join "`r`n"
try{ $textoFinal | Set-Clipboard; W-Log "`n[CLIPBOARD] Salida copiada - OK" } catch { W-Log "[CLIPBOARD] Error: $($_.Exception.Message)" }
W-Log "=== FIN DEEP INSPECTOR ==="
