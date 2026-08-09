param(
  [string]$InputMd = "",
  [string]$UnidadHint = "KW 519",
  [ValidateSet("DryRun","Apply")]
  [string]$Mode = "DryRun",
  [string]$OutputRoot = "C:\RUNEFOGE_PRO\rf_temp",
  [string]$TimezoneOffset = "-06:00",
  [switch]$UpdateNote
)

Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)

$Fecha=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Stamp=Get-Date -Format "yyyyMMdd_HHmmss"
Write-Host "[RF_TGL_TELEMETRIA_MD_PARSER_V1][$Fecha]"
Write-Host "[MODE] $Mode"

function Normalize-TextKey {
  param([string]$Text)
  if($null -eq $Text){ return "campo" }
  $x=$Text.Trim().ToLowerInvariant()
  $x=$x -replace "á","a" -replace "é","e" -replace "í","i" -replace "ó","o" -replace "ú","u" -replace "ñ","n"
  $x=$x -replace "[^a-z0-9]+","_"
  $x=$x.Trim("_")
  if([string]::IsNullOrWhiteSpace($x)){ return "campo" }
  return $x
}

function Get-SafeUnit {
  param([string]$Text)
  $m=[regex]::Match($Text,"(?i)\b(KW|CT|TQ|UNIDAD)\s*[-_ ]?\s*(\d+)\b")
  if($m.Success){ return (($m.Groups[1].Value.ToUpperInvariant()) + " " + $m.Groups[2].Value) }
  return "PENDIENTE"
}

function Get-Number {
  param([object]$Value)
  if($null -eq $Value){ return $null }
  $t=("$Value").Trim()
  if([string]::IsNullOrWhiteSpace($t)){ return $null }
  $t=$t -replace "\\",""
  $t=$t -replace ",","."
  $m=[regex]::Match($t,"-?\d+(\.\d+)?")
  if(!$m.Success){ return $null }
  return [double]::Parse($m.Value,[Globalization.CultureInfo]::InvariantCulture)
}

function Normalize-Cell {
  param([object]$Value)
  if($null -eq $Value){ return $null }
  $t=("$Value").Trim()
  $t=$t -replace "\\",""
  if([string]::IsNullOrWhiteSpace($t)){ return $null }
  if($t -match "^-+$"){ return $null }
  if($t -eq "---"){ return $null }
  return $t
}

function Split-MarkdownRow {
  param([string]$Line)
  $x=$Line.Trim()
  $x=$x -replace "^\|",""
  $x=$x -replace "\|$",""
  return @($x -split "\|" | ForEach-Object { $_.Trim() })
}

function Find-InputMarkdown {
  param([string]$InputMd,[string]$UnidadHint)
  if($InputMd -and (Test-Path -LiteralPath $InputMd)){ return (Resolve-Path -LiteralPath $InputMd).Path }

  $Roots=@(
    "C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_OBSIDIAN",
    "C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO",
    "C:\RUNEFOGE_PRO\rf_temp"
  )

  $Pattern="*.md"
  if($UnidadHint -and $UnidadHint -ne "PENDIENTE"){
    $Pattern="*" + ($UnidadHint -replace "\s+","*") + "*.md"
  }

  $Candidates=@()
  foreach($r in $Roots){
    if(Test-Path -LiteralPath $r){
      $Candidates += Get-ChildItem -LiteralPath $r -Recurse -File -Filter $Pattern -ErrorAction SilentlyContinue
    }
  }

  foreach($f in ($Candidates | Sort-Object LastWriteTime -Descending)){
    $raw=Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    if($raw -match "\|\s*#\s*\|\s*Tiempo\s*\|" -or $raw -match "\|\s*Tiempo\s*\|\s*Ignicion\s*\|"){
      return $f.FullName
    }
  }

  return $null
}

function Convert-ToUtcIso {
  param([string]$Raw,[string]$Offset)
  $clean=Normalize-Cell $Raw
  if(!$clean){ return $null }
  $dt=[datetime]::ParseExact($clean,"yyyy-MM-dd HH:mm:ss",[Globalization.CultureInfo]::InvariantCulture)
  if($Offset -match "^[+-]\d\d:\d\d$"){
    $dto=[datetimeoffset]::new($dt,[timespan]::Parse($Offset.Replace("+","")))
    if($Offset.StartsWith("-")){
      $hh=[int]$Offset.Substring(1,2)
      $mm=[int]$Offset.Substring(4,2)
      $dto=[datetimeoffset]::new($dt,-([timespan]::new($hh,$mm,0)))
    }
    return $dto.UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
  }
  return $dt.ToString("yyyy-MM-ddTHH:mm:ss")
}

$InputPath=Find-InputMarkdown -InputMd $InputMd -UnidadHint $UnidadHint

if(!$InputPath){
  [pscustomobject]@{
    Estado="PENDIENTE_INPUT_MD"
    Motivo="No encontré nota Markdown con tabla de telemetría."
    ComoObtener="Exporta o ubica la nota .md de Obsidian y ejecuta: -InputMd `"C:\ruta\KW 519 prueba obsidyan extractor datos.md`""
    Backend="NO_TOCADO"
  } | Format-List
  exit 2
}

$Raw=Get-Content -LiteralPath $InputPath -Raw
$Lines=$Raw -split "`r?`n"
$Unidad=if($UnidadHint){$UnidadHint}else{Get-SafeUnit ([IO.Path]::GetFileNameWithoutExtension($InputPath))}
if($Unidad -eq "PENDIENTE"){ $Unidad=Get-SafeUnit $Raw }
$UnidadSafe=($Unidad -replace "\s+","_")

$HeaderIndex=-1
for($i=0; $i -lt $Lines.Count; $i++){
  if($Lines[$i] -match "^\|\s*#\s*\|\s*Tiempo\s*\|" -or $Lines[$i] -match "^\|\s*Tiempo\s*\|\s*Ignicion\s*\|"){
    $HeaderIndex=$i
    break
  }
}

if($HeaderIndex -lt 0){
  throw "NO_SE_ENCONTRO_TABLA_TELEMETRIA: $InputPath"
}

$Headers=Split-MarkdownRow $Lines[$HeaderIndex]
$Rows=@()

for($i=$HeaderIndex+1; $i -lt $Lines.Count; $i++){
  $line=$Lines[$i]
  if($line -notmatch "^\|"){ break }
  $cells=Split-MarkdownRow $line
  $isSeparator=@($cells | Where-Object { $_ -notmatch "^-+$" }).Count -eq 0
  if($isSeparator){ continue }
  if($cells.Count -lt 2){ continue }

  while($cells.Count -lt $Headers.Count){ $cells += "" }
  if($cells.Count -gt $Headers.Count){ $cells=$cells[0..($Headers.Count-1)] }

  $rawObj=[ordered]@{}
  for($c=0; $c -lt $Headers.Count; $c++){
    $rawObj[$Headers[$c]]=$cells[$c]
  }
  $Rows += [pscustomobject]$rawObj
}

$Records=@()
$EmptyRows=0
$BadRows=0

foreach($row in $Rows){
  $h=$row.PSObject.Properties
  $tiempo=(Normalize-Cell ($h["Tiempo"].Value))
  if(!$tiempo){ $BadRows++; continue }

  try{ $tsIso=Convert-ToUtcIso -Raw $tiempo -Offset $TimezoneOffset }catch{ $BadRows++; continue }

  $calidad=Normalize-Cell ($h["Calidad de Señal"].Value)
  $calidadNombre=$null
  $calidadDbm=$null
  if($calidad){
    $calidadNombre=($calidad -replace "\s*\(.*$","").Trim()
    $calidadDbm=Get-Number $calidad
  }

  $rec=[ordered]@{
    schema="rf.telemetry.tgl.v1"
    unidad=$Unidad
    ts=$tsIso
    tiempo_original=$tiempo
    timezone_offset_aplicado=$TimezoneOffset
    row_index=Get-Number ($h["#"].Value)
    ignicion=Normalize-Cell ($h["Ignicion"].Value)
    combustible_tanque1_l=Get-Number ($h["Nivel de Combustible Tanque 1"].Value)
    voltaje_unidad_v=Get-Number ($h["Voltaje Unidad"].Value)
    combustible_tanque2_l=Get-Number ($h["Nivel de Combustible Tanque 2"].Value)
    antijammer=Normalize-Cell ($h["Antijammer"].Value)
    combustible_total_l=Get-Number ($h["Total de Combustible"].Value)
    voltaje_gps_v=Get-Number ($h["Voltaje GPS"].Value)
    temperatura_t1_c=Get-Number ($h["Temperatura T1"].Value)
    paro_motor_1=Normalize-Cell ($h["Paro de Motor 1"].Value)
    temperatura_t2_c=Get-Number ($h["Temperatura T2"].Value)
    paro_motor_2=Normalize-Cell ($h["Paro de Motor 2"].Value)
    status_motor=Normalize-Cell ($h["Status Motor"].Value)
    paro_motor_3=Normalize-Cell ($h["Paro de Motor 3"].Value)
    calidad_senal=$calidadNombre
    calidad_senal_dbm=$calidadDbm
    velocidad_gps=Get-Number ($h["Velocidad Gps"].Value)
    status_paro_seguridad=Normalize-Cell ($h["Status Paro Seguridad"].Value)
    odometro_km=Get-Number ($h["Odometro"].Value)
    id_button=Normalize-Cell ($h["ID button"].Value)
  }

  $hasUseful=$false
  foreach($k in $rec.Keys){
    if($k -notin @("schema","unidad","ts","tiempo_original","timezone_offset_aplicado","row_index")){
      if($null -ne $rec[$k]){ $hasUseful=$true; break }
    }
  }

  if(!$hasUseful){
    $EmptyRows++
    continue
  }

  $Records += [pscustomobject]$rec
}

$seen=@{}
$Unique=@()
$DupRows=0

foreach($r in $Records){
  $key=("{0}|{1}|{2}|{3}|{4}|{5}|{6}" -f $r.unidad,$r.ts,$r.ignicion,$r.voltaje_unidad_v,$r.combustible_tanque1_l,$r.combustible_tanque2_l,$r.calidad_senal_dbm)
  if($seen.ContainsKey($key)){
    $DupRows++
  }else{
    $seen[$key]=$true
    $Unique += $r
  }
}

function Get-Stats {
  param([object[]]$Data,[string]$Field)
  $vals=@($Data | ForEach-Object { $_.$Field } | Where-Object { $null -ne $_ })
  if($vals.Count -eq 0){ return [pscustomobject]@{min=$null;max=$null;avg=$null;count=0} }
  return [pscustomobject]@{
    min=[math]::Round(($vals | Measure-Object -Minimum).Minimum,2)
    max=[math]::Round(($vals | Measure-Object -Maximum).Maximum,2)
    avg=[math]::Round(($vals | Measure-Object -Average).Average,2)
    count=$vals.Count
  }
}

$FuelTotal=Get-Stats $Unique "combustible_total_l"
$FuelT1=Get-Stats $Unique "combustible_tanque1_l"
$FuelT2=Get-Stats $Unique "combustible_tanque2_l"
$Volt=Get-Stats $Unique "voltaje_unidad_v"
$SignalGroups=@($Unique | Where-Object {$_.calidad_senal} | Group-Object calidad_senal | Sort-Object Name)
$AntiGroups=@($Unique | Where-Object {$_.antijammer} | Group-Object antijammer | Sort-Object Name)

$VoltLow=@($Unique | Where-Object { $_.voltaje_unidad_v -ne $null -and $_.voltaje_unidad_v -lt 12.5 }).Count
$VoltHigh=@($Unique | Where-Object { $_.voltaje_unidad_v -ne $null -and $_.voltaje_unidad_v -gt 14.8 }).Count
$FuelNegative=@($Unique | Where-Object { ($_.combustible_total_l -lt 0) -or ($_.combustible_tanque1_l -lt 0) -or ($_.combustible_tanque2_l -lt 0) }).Count
$SignalBad=@($Unique | Where-Object { $_.calidad_senal -match "Mala" }).Count

$RegistrosConTiempo=@($Unique | Where-Object { $_.PSObject.Properties.Name -contains "tiempo_original" -and (-not [string]::IsNullOrWhiteSpace([string]$_.tiempo_original)) } | Sort-Object tiempo_original)
$RegistrosConTiempo=@($Unique | Where-Object { $_.PSObject.Properties.Name -contains "tiempo_original" -and (-not [string]::IsNullOrWhiteSpace([string]$_.tiempo_original)) } | Sort-Object tiempo_original)
$PrimerRegistro=$null
$UltimoRegistro=$null
if($RegistrosConTiempo.Count -gt 0){
  $PrimerRegistro=$RegistrosConTiempo[0]
  $UltimoRegistro=$RegistrosConTiempo[$RegistrosConTiempo.Count-1]
}
$FirstSourceDate=if($PrimerRegistro -and $PrimerRegistro.tiempo_original -and ([string]$PrimerRegistro.tiempo_original).Length -ge 10){ ([string]$PrimerRegistro.tiempo_original).Substring(0,10) }else{ Get-Date -Format "yyyy-MM-dd" }
$RangoInicioTexto=if($PrimerRegistro){ $PrimerRegistro.tiempo_original }else{ "PENDIENTE" }
$RangoFinTexto=if($UltimoRegistro){ $UltimoRegistro.tiempo_original }else{ "PENDIENTE" }
$RangoInicioTexto=if($PrimerRegistro){ $PrimerRegistro.tiempo_original }else{ "PENDIENTE" }
$RangoFinTexto=if($UltimoRegistro){ $UltimoRegistro.tiempo_original }else{ "PENDIENTE" }
$OutDir=Join-Path $OutputRoot $UnidadSafe
$JsonPath=Join-Path $OutDir ("{0}_telemetria_{1}.json" -f $UnidadSafe,$FirstSourceDate)
$CsvPath=Join-Path $OutDir ("{0}_telemetria_{1}.csv" -f $UnidadSafe,$FirstSourceDate)
$ReportPath=Join-Path $OutDir ("{0}_resumen_diagnostico.md" -f $UnidadSafe)

$SignalText=($SignalGroups | ForEach-Object { "- $($_.Name): $($_.Count)" }) -join "`n"
$AntiText=($AntiGroups | ForEach-Object { "- $($_.Name): $($_.Count)" }) -join "`n"

$ReportLines=@(
"# Diagnóstico telemetría $Unidad",
"",
"## Resumen",
"- Archivo origen: $InputPath",
"- Filas originales detectadas: $($Rows.Count)",
"- Filas válidas únicas: $($Unique.Count)",
"- Filas vacías eliminadas: $EmptyRows",
"- Filas duplicadas eliminadas: $DupRows",
"- Filas con error de timestamp: $BadRows",
"- Rango inicio: $RangoInicioTexto",
"- Rango fin: $RangoFinTexto",
"",
"## Estadísticas",
"| Métrica | Min | Max | Promedio | Count |",
"|---|---:|---:|---:|---:|",
"| Combustible total l | $($FuelTotal.min) | $($FuelTotal.max) | $($FuelTotal.avg) | $($FuelTotal.count) |",
"| Tanque 1 l | $($FuelT1.min) | $($FuelT1.max) | $($FuelT1.avg) | $($FuelT1.count) |",
"| Tanque 2 l | $($FuelT2.min) | $($FuelT2.max) | $($FuelT2.avg) | $($FuelT2.count) |",
"| Voltaje unidad V | $($Volt.min) | $($Volt.max) | $($Volt.avg) | $($Volt.count) |",
"",
"## Calidad de señal",
$SignalText,
"",
"## Antijammer",
$AntiText,
"",
"## Anomalías rápidas",
"- Voltaje bajo < 12.5V: $VoltLow",
"- Voltaje alto > 14.8V: $VoltHigh",
"- Combustible negativo: $FuelNegative",
"- Señal mala: $SignalBad",
"",
"## SQLite futuro",
'```sql',
"CREATE TABLE IF NOT EXISTS telemetry_tgl (",
"  id INTEGER PRIMARY KEY AUTOINCREMENT,",
"  unidad TEXT NOT NULL,",
"  ts TEXT NOT NULL,",
"  ignicion TEXT,",
"  combustible_tanque1_l REAL,",
"  combustible_tanque2_l REAL,",
"  combustible_total_l REAL,",
"  voltaje_unidad_v REAL,",
"  voltaje_gps_v REAL,",
"  temperatura_t1_c REAL,",
"  temperatura_t2_c REAL,",
"  antijammer TEXT,",
"  calidad_senal TEXT,",
"  calidad_senal_dbm REAL,",
"  raw_json TEXT,",
"  created_at TEXT DEFAULT CURRENT_TIMESTAMP,",
"  UNIQUE(unidad, ts, ignicion, voltaje_unidad_v, combustible_tanque1_l, combustible_tanque2_l, calidad_senal_dbm)",
");",
'```',
"",
"## Endpoint futuro",
'```txt',
"GET /api/telemetry/tgl/:unidad?from=YYYY-MM-DD&to=YYYY-MM-DD",
'```'
)

$Summary=[ordered]@{
  Estado="DRYRUN_OK"
  Mode=$Mode
  Unidad=$Unidad
  Input=$InputPath
  FilasOriginales=$Rows.Count
  FilasValidasUnicas=$Unique.Count
  FilasVacias=$EmptyRows
  FilasDuplicadas=$DupRows
  FilasErrorTimestamp=$BadRows
  Json=$JsonPath
  Csv=$CsvPath
  Report=$ReportPath
  Backend="NO_TOCADO"
  N8n="NO_TOCADO"
  SQLiteProductivo="NO_TOCADO"
}

if($Mode -eq "Apply"){
  New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

  foreach($p in @($JsonPath,$CsvPath,$ReportPath)){
    if(Test-Path -LiteralPath $p){
      Copy-Item -LiteralPath $p -Destination ($p + ".backup_$Stamp") -Force
    }
  }

  $Unique | ForEach-Object { $_ | ConvertTo-Json -Depth 10 -Compress } | Set-Content -LiteralPath $JsonPath -Encoding utf8
  $Unique | Export-Csv -LiteralPath $CsvPath -NoTypeInformation -Encoding utf8
  $ReportLines | Set-Content -LiteralPath $ReportPath -Encoding utf8

  if($UpdateNote){
    $noteLines=Get-Content -LiteralPath $InputPath
    $meta=@(
      "rf_unit: `"$Unidad`"",
      "rf_data_type: `"telemetria_tgl`"",
      "rf_ready_for_carnets: true",
      "rf_ready_for_runeforge_sqlite: false",
      "rf_next_action: `"normalizar_tabla_md_a_json_csv`"",
      "rf_processed_timestamp: `"$(Get-Date -Format o)`""
    )
    $verdict=@(
      "## [VEREDICTO RÁPIDO]",
      "",
      '```txt',
      "estado=CAPTURA_VALIDA",
      "tipo_captura=telemetria_tgl_tabla",
      "unidad=$Unidad",
      "sirve_para=analisis_combustible_voltaje_senal_eventos",
      "siguiente_accion=normalizar_a_json_csv",
      "riesgo_datos_sensibles=REVISAR",
      "calidad_extraccion=BUENA",
      "observacion=Tabla normalizada por RF_TGL_TELEMETRIA_MD_PARSER_V1.",
      '```',
      ""
    )

    $newLines=@()
    if($noteLines.Count -gt 0 -and $noteLines[0] -eq "---"){
      $close=-1
      for($i=1;$i -lt $noteLines.Count;$i++){ if($noteLines[$i] -eq "---"){ $close=$i; break } }
      if($close -gt 0){
        $fm=@($noteLines[1..($close-1)] | Where-Object { $_ -notmatch "^rf_(unit|data_type|ready_for_carnets|ready_for_runeforge_sqlite|next_action|processed_timestamp):" })
        $body=@($noteLines[($close+1)..($noteLines.Count-1)])
        if(($body -join "`n") -notmatch "\[VEREDICTO RÁPIDO\]"){ $body=$verdict + $body }
        $newLines=@("---") + $fm + $meta + @("---") + $body
      }
    }

    if($newLines.Count -eq 0){
      $newLines=@("---") + $meta + @("---") + $verdict + $noteLines
    }

    Copy-Item -LiteralPath $InputPath -Destination ($InputPath + ".backup_$Stamp") -Force
    $newLines | Set-Content -LiteralPath $InputPath -Encoding utf8
  }

  $Summary.Estado="APPLY_DONE"
}

[pscustomobject]$Summary | Format-List

Write-Host "`n[STATS]"
[pscustomobject]@{
  FuelTotalMin=$FuelTotal.min
  FuelTotalMax=$FuelTotal.max
  FuelTotalAvg=$FuelTotal.avg
  VoltMin=$Volt.min
  VoltMax=$Volt.max
  VoltAvg=$Volt.avg
  SignalBad=$SignalBad
  VoltLow=$VoltLow
  Duplicates=$DupRows
} | Format-List

if($Mode -eq "DryRun"){
  Write-Host "`n[DRYRUN] No se escribieron JSON/CSV/MD. Para generar archivos usa -Mode Apply."
}
