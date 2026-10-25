$ErrorActionPreference = 'Continue'
$Salida = New-Object System.Collections.Generic.List[string]
function W-Log { param([string]$t) $Salida.Add($t); Write-Host $t }

$jsonPath = "C:\RUNEFORGE_V2_CORE\reports\html_audit_20261020_225625.json"

W-Log "=== JSON RAW DUMPER - DEBUG ==="
W-Log "Archivo: $jsonPath"
W-Log "--------------------------------------------------"

$raw = Get-Content $jsonPath -Raw
W-Log "[RAW] Primeros 1000 chars:"
W-Log $raw.Substring(0, [math]::Min(1000, $raw.Length))
W-Log "`n[RAW] Total chars: $($raw.Length)"

try{
    $data = $raw | ConvertFrom-Json
    W-Log "`n[OBJ] Tipo: $($data.GetType().Name) | Count: $($data.Count)"
    if($data.Count -gt 0){
        $first = $data[0]
        W-Log "`n[OBJ 0] Propiedades reales:"
        $first.PSObject.Properties | ForEach-Object { W-Log (" - {0} = {1} (Tipo: {2})" -f $_.Name, $_.Value, $_.TypeNameOfValue) }
        W-Log "`n[OBJ 0] JSON pretty:"
        $first | ConvertTo-Json -Depth 4 | ForEach-Object { W-Log $_ }
        
        if($data.Count -gt 1){
            $second = $data[1]
            W-Log "`n[OBJ 1] Propiedades:"
            $second.PSObject.Properties | ForEach-Object { W-Log (" - {0} = {1}" -f $_.Name, $_.Value) }
        }
    }

    W-Log "`n[RESUMEN] Agrupando por campo que parezca clasificacion"
    $posiblesClas = @('clasificacion','tipo','categoria','category','type','class')
    foreach($campo in $posiblesClas){
        if($data[0].PSObject.Properties.Name -contains $campo){
            $grupo = $data | Group-Object $campo | Sort-Object Count -Descending | Select-Object -First 5
            W-Log "Campo '$campo' encontrado:"
            $grupo | ForEach-Object { W-Log ("  {0}: {1}" -f $_.Name, $_.Count) }
        }
    }

    W-Log "`n[RESUMEN] Campos de path/tamaño"
    $posiblesPath = @('path','Path','fullPath','file','archivo','ruta','FullName','name')
    foreach($campo in $posiblesPath){
        if($data[0].PSObject.Properties.Name -contains $campo){
            W-Log "Campo path encontrado: '$campo' ejemplo: $($data[0].$campo)"
        }
    }

} catch { W-Log "[ERROR] $($_.Exception.Message)" }

$textoFinal = $Salida -join "`r`n"
try{ $textoFinal | Set-Clipboard; W-Log "`n[CLIPBOARD] Copiado OK" } catch {}
W-Log "=== FIN DUMPER ==="
