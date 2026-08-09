param([string]$Query="",[int]$Max=20)
$ErrorActionPreference="Stop"
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$Root="C:\RUNEFOGE_PRO\runeforge"
$IndexDir=Join-Path $Root "data\memory\index"
$TraceDir=Join-Path $Root "data\memory\traces"
New-Item -ItemType Directory -Force -Path $TraceDir | Out-Null
$latest=Get-ChildItem -LiteralPath $IndexDir -Filter "rf_memory_index_v1_*.json" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if(-not $latest){throw "No existe indice RF_MEMORY_INDEX_V1"}
$idx=Get-Content -LiteralPath $latest.FullName -Raw | ConvertFrom-Json
$q=$Query.Trim()
$results=@()
foreach($r in $idx.files){$path=Join-Path $idx.import_dir $r.relative_path; $raw=""; if(Test-Path -LiteralPath $path){$raw=Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue}; $hit=($q -eq "" -or $r.file -match [regex]::Escape($q) -or $r.kind -match [regex]::Escape($q) -or $r.relative_path -match [regex]::Escape($q) -or $raw -match [regex]::Escape($q)); if($hit){$snippet=""; if($q -ne "" -and $raw -match [regex]::Escape($q)){ $pos=$raw.IndexOf($q,[System.StringComparison]::OrdinalIgnoreCase); if($pos -ge 0){$start=[Math]::Max(0,$pos-80); $len=[Math]::Min(220,$raw.Length-$start); $snippet=($raw.Substring($start,$len) -replace "`r|`n"," ")}}; $hash=if($r.sha256){$r.sha256.Substring(0,12)}else{"NOHASH"}; $results += [pscustomobject]@{file=$r.file;kind=$r.kind;extension=$r.extension;lines=$r.lines;bytes=$r.bytes;hash=$hash;snippet=$snippet}}}
$results=$results | Select-Object -First $Max
$stamp=Get-Date -Format "yyyyMMdd_HHmmss"
$Trace=Join-Path $TraceDir "rf_memory_search_v1_$stamp.json"
$traceObj=[ordered]@{ts=(Get-Date).ToString("o");event="RF_MEMORY_SEARCH_V1";query=$q;index=$latest.FullName;results=$results.Count;backend="NO_TOCADO";next="VALIDAR_BUSQUEDA_Y_CREAR_SQLITE_DESPUES"}
$traceObj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Trace -Encoding utf8BOM -Force
Write-Host "[RF_MEMORY_SEARCH_V1]"
[pscustomobject]@{Query=$q;Index=$latest.FullName;ImportDir=$idx.import_dir;Results=$results.Count;Trace=$Trace;Backend="NO_TOCADO"} | Format-List
Write-Host "`n[RESULTS]"
$results | Format-Table file,kind,extension,lines,bytes,hash -AutoSize
Write-Host "`n[SUMMARY]"
[pscustomobject]@{Estado="RF_MEMORY_SEARCH_V1_DONE";Query=$q;Results=$results.Count;Backend="NO_TOCADO";Siguiente="VALIDAR_BUSQUEDA_Y_CREAR_SQLITE_DESPUES"} | Format-List
