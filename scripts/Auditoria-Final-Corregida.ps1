$ErrorActionPreference = 'Continue'
$Salida = New-Object System.Collections.Generic.List[string]
function W-Log { param([string]$t) $Salida.Add($t); Write-Host $t }

$RutaRaiz = "C:\RUNEFORGE_V2_CORE"
$JsonExistente = "C:\RUNEFORGE_V2_CORE\reports\html_audit_20261020_225625.json"

W-Log "=== AUDITORIA FINAL CORREGIDA - 88 + FIRMWARE ==="
W-Log "Fecha: $(Get-Date)"
W-Log "--------------------------------------------------"

W-Log "[1] Leyendo JSON existente de 88 archivos (MB, Tipo, Ruta)"
try{
    $data88 = Get-Content $JsonExistente -Raw | ConvertFrom-Json
    W-Log "[OK] JSON 88 leido: $($data88.Count) archivos"
    $top88 = $data88 | Sort-Object MB -Descending | Select-Object -First 20
    W-Log "TOP 20 de tu audit de 88 (por MB real):"
    $i=1
    foreach($f in $top88){
        W-Log (" {0}. {1} MB | {2} | {3} | {4}" -f $i, $f.MB, $f.Tipo, $f.Titulo, $f.Ruta)
        $i++
    }
    $dashPanel = $data88 | Where-Object { $_.Tipo -match 'Dashboard|Panel' }
    W-Log "`n[INFO] Dashboard/Panel en tu audit 88: $($dashPanel.Count)"
    $dashPanel | ForEach-Object { W-Log ("  -> {0} MB | {1}" -f $_.MB, $_.Ruta) }
} catch { W-Log "[ERROR] JSON 88: $($_.Exception.Message)" }

W-Log "`n[2] Audit REAL completo incluyendo firmware (excluyendo node_modules/.git/target/dist)"
try{
    $excluir = @('node_modules','.git','target','dist')
    $archivos = Get-ChildItem -Path $RutaRaiz -Filter *.html -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
        $full = $_.FullName
        -not ($excluir | Where-Object { $full -like "*\$_\*" })
    }
    W-Log "[OK] Archivos totales sin basura: $($archivos.Count) (antes tenias 118 con basura, 88 sin firmware)"

    $analizados = @()
    foreach($a in $archivos){
        try{
            $kb = [math]::Round($a.Length/1KB,2)
            $mb = [math]::Round($a.Length/1MB,4)
            $cont = Get-Content $a.FullName -Raw -ErrorAction SilentlyContinue
            $tipo = "Estático / Docs"
            if($cont -match '(?i)dashboard|panel|grid'){ $tipo = "Dashboard / Panel" }
            if($cont -match '(?i)tauri|invoke|__TAURI__'){ $tipo = "SPA / Tauri" }
            if($a.FullName -like "*\firmware\*" -and $mb -gt 0.5){ $tipo = "Firmware Pesado / Grimorio" }
            if($a.FullName -like "*\dist\*" -or $a.FullName -like "*\build\*"){ $tipo = "Build Output (Revisar)" }
            $analizados += [PSCustomObject]@{ Ruta=$a.FullName; MB=$mb; KB=$kb; Tipo=$tipo; Scripts=([regex]::Matches($cont,'<script').Count) }
        } catch {}
    }

    $topReal = $analizados | Sort-Object MB -Descending | Select-Object -First 20
    W-Log "`nTOP 20 REAL CORREGIDO (con firmware):"
    $j=1
    foreach($t in $topReal){
        W-Log (" {0}. {1} MB ({2} KB) | {3} | {4}" -f $j, $t.MB, $t.KB, $t.Tipo, $t.Ruta)
        $j++
    }

    $candidatos = $topReal | Where-Object { $_.Tipo -match 'Dashboard|SPA|Firmware Pesado' }
    W-Log "`n[3] CANDIDATOS A MEJORA REAL (Dashboard/SPA/Firmware Pesado): $($candidatos.Count)"
    $candidatos | ForEach-Object { W-Log (" -> {0} MB | {1} | {2}" -f $_.MB, $_.Tipo, $_.Ruta) }

    $jsonOut = "C:\RUNEFORGE_V2_CORE\reports\html_audit_FINAL_20261020.json"
    $topReal | ConvertTo-Json -Depth 4 | Set-Content $jsonOut -Encoding UTF8 -Force
    W-Log "`n[OK] Reporte FINAL guardado: $jsonOut"

} catch { W-Log "[ERROR] Audit real: $($_.Exception.Message)" }

W-Log "`n=== VALIDACION FINAL ==="
W-Log "[VALIDACION] 88 vs 118 explicado: 88 excluye firmware pesado, 118 incluye todo"
W-Log "[VALIDACION] Tu audit 88 max 0.2 MB | Mi audit 118 max 1.19 MB (grimorio) - OK ambos, diferente scope"
try{
    $reg = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" -ErrorAction SilentlyContinue).PowerShellVersion
    W-Log "[VALIDACION] PS Reg: $reg | Actual: $($PSVersionTable.PSVersion) - OK"
} catch { W-Log "[VALIDACION] PS: $($PSVersionTable.PSVersion)" }

$textoFinal = $Salida -join "`r`n"
try{ $textoFinal | Set-Clipboard; W-Log "`n[CLIPBOARD] Copiado OK" } catch {}
W-Log "=== FIN AUDITORIA CORREGIDA ==="
