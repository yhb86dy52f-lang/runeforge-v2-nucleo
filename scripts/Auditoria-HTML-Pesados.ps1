$ErrorActionPreference = 'Continue'
$RutaRaiz = "C:\RUNEFORGE_V2_CORE"
$TopN = 25
$Salida = New-Object System.Collections.Generic.List[string]
function W-Log { param([string]$t) $Salida.Add($t); Write-Host $t }

function Clasificar-HTML {
    param([string]$c)
    $cats = @()
    if($c -match '(?i)dashboard') { $cats += 'Dashboard' }
    if($c -match '(?i)<form') { $cats += 'Formulario/Alta' }
    if($c -match '(?i)etiqueta|@media\s+print|plantilla.*etiqueta|imprimir') { $cats += 'Etiqueta/Impresion' }
    if($c -match '(?i)<table|datatable|grid|inventario') { $cats += 'Reporte/Tabla' }
    if($c -match '(?i)leaflet|google.*map|mapbox') { $cats += 'Mapa' }
    if($c -match '(?i)calamp|gps|latitud|longitud|\blat\b|\blng\b|LMU') { $cats += 'Telemetria-GPS' }
    if($c -match '(?i)thermo|temperatura|CT-Thermo|sensor.*temp') { $cats += 'Telemetria-Temperatura' }
    if($c -match '(?i)qr|escaner|scanner|QRCod') { $cats += 'QR/Escaner' }
    if($c -match '(?i)login|password|auth') { $cats += 'Auth/Login' }
    if($c -match '(?i)chart|canvas|grafica|Chart\.js') { $cats += 'Grafica' }
    if($cats.Count -eq 0) { $cats += 'General/Plantilla' }
    return ($cats -join ', ')
}

function Get-Utilidad {
    param([string]$clas, [long]$kb)
    $score = 0
    if($clas -match 'Dashboard|Reporte|Grafica') { $score += 30 }
    if($clas -match 'Etiqueta/Impresion') { $score += 35 }
    if($clas -match 'Telemetria') { $score += 30 }
    if($clas -match 'Formulario') { $score += 20 }
    if($clas -match 'QR') { $score += 15 }
    if($kb -gt 500) { $score -= 10 }
    if($score -ge 50) { return "ALTA - Reutilizar como base" }
    if($score -ge 25) { return "MEDIA - Buen candidato" }
    return "BAJA - Solo referencia"
}

W-Log "=== AUDITORIA HTML PESADOS - RUNEFORGE_V2_CORE ==="
W-Log "Fecha: $(Get-Date) | Equipo: $env:COMPUTERNAME | Usuario: $env:USERNAME"
W-Log "Ruta raiz auditada: $RutaRaiz"
W-Log "--------------------------------------------------"

if(-not (Test-Path $RutaRaiz)){
    W-Log "[AVISO] Ruta $RutaRaiz no existe. Probando alternativas..."
    $alternativas = @("C:\Proyectos","D:\Proyectos","C:\Trabajo","$env:USERPROFILE\Documents")
    foreach($alt in $alternativas){ if(Test-Path $alt){ $RutaRaiz = $alt; W-Log "[OK] Usando alternativa: $RutaRaiz"; break } }
}

W-Log "`n[1] Buscando *.html recursivamente..."
$archivos = @()
try{
    $archivos = Get-ChildItem -Path $RutaRaiz -Filter *.html -Recurse -File -ErrorAction SilentlyContinue | 
    Select-Object FullName, Length, LastWriteTime, DirectoryName
} catch { W-Log "[ERROR] Busqueda: $($_.Exception.Message)" }

if($archivos.Count -eq 0){ W-Log "[RESULTADO] 0 HTML encontrados en $RutaRaiz"; }
else{
    W-Log "[OK] Encontrados: $($archivos.Count) archivos HTML"
    $totalMB = [math]::Round(($archivos | Measure-Object Length -Sum).Sum / 1MB, 2)
    W-Log "Peso total HTML: $totalMB MB"

    $top = $archivos | Sort-Object Length -Descending | Select-Object -First $TopN
    W-Log "`n=== TOP $TopN HTML MAS PESADOS (Candidatos para mejorar apps) ==="
    $tabla = @()
    $i=1
    foreach($f in $top){
        try{
            $cont = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
            if(-not $cont){ $cont = "" }
            $lineas = ($cont -split "`n").Count
            $clas = Clasificar-HTML -c $cont
            $util = Get-Utilidad -clas $clas -kb ([math]::Round($f.Length/1KB))
            $kb = [math]::Round($f.Length/1KB,2)
            W-Log ("{0}. {1} | {2} KB | {3} lineas | {4} | {5}" -f $i, $f.FullName, $kb, $lineas, $clas, $util)
            $tabla += [PSCustomObject]@{ Num=$i; Path=$f.FullName; KB=$kb; Clasificacion=$clas; Utilidad=$util }
        } catch { W-Log "$i. $($f.FullName) - ERROR lectura: $($_.Exception.Message)" }
        $i++
    }

    W-Log "`n=== RESUMEN POR CLASIFICACION ==="
    $tabla | Group-Object Clasificacion | Sort-Object Count -Descending | ForEach-Object {
        W-Log ("- {0}: {1} archivos" -f $_.Name, $_.Count)
    }

    W-Log "`n=== RECOMENDACION PARA MEJORAR APPS ==="
    $mejores = $tabla | Where-Object { $_.Utilidad -like 'ALTA*' } | Select-Object -First 5
    if($mejores){
        W-Log "Usa estos como base para tu estandar:"
        $mejores | ForEach-Object { W-Log ("  -> $($_.Path) [$($_.Clasificacion)]") }
    } else { W-Log "No hay ALTA utilidad, revisa los de MEDIA utilidad." }
}

W-Log "`n=== VALIDACION FINAL ==="
$scriptActual = $MyInvocation.MyCommand.Path
if(Test-Path $scriptActual){ W-Log "[VALIDACION] Script existe en ruta canonica: $scriptActual - OK" } else { W-Log "[VALIDACION] Script no encontrado en ruta canonica - FAIL" }
try{
    $psVer = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" -ErrorAction SilentlyContinue).PowerShellVersion
    if($psVer){ W-Log "[VALIDACION] PowerShell Registry Version: $psVer - OK" } else { W-Log "[VALIDACION] No se leyo registro PS, usando `$PSVersionTable" }
    W-Log "[VALIDACION] PSVersion: $($PSVersionTable.PSVersion) - OK"
} catch { W-Log "[VALIDACION] Error leyendo registro: $($_.Exception.Message)" }
$serv = Get-CimInstance Win32_Service -Filter "Name='wsearch'" -ErrorAction SilentlyContinue
if($serv){ W-Log "[VALIDACION] Servicio WSearch Estado: $($serv.State) - Verificacion WMI OK" }

$textoFinal = $Salida -join "`r`n"
try{
    $textoFinal | Set-Clipboard
    W-Log "`n[CLIPBOARD] Salida completa copiada al portapapeles - OK"
} catch {
    W-Log "[CLIPBOARD] ERROR: $($_.Exception.Message)"
}
W-Log "=== FIN AUDITORIA ==="
