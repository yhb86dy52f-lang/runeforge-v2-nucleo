$ErrorActionPreference="Stop"
$Fecha=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[RF_ROOT_CLEANUP_ROLLBACK_CURRENT][$Fecha]"
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$RollbackJson="C:\RUNEFOGE_PRO\runeforge\data\maintenance\root_cleanup\rf_root_cleanup_rollback_manifest_current.json"
if(!(Test-Path -LiteralPath $RollbackJson)){throw "NO_EXISTE_ROLLBACK_MANIFEST: $RollbackJson"}
$Data=Get-Content -LiteralPath $RollbackJson -Raw | ConvertFrom-Json
$Movidos=0
foreach($Item in $Data.items){
  $Origen="$($Item.MovidoA)"
  $Destino="$($Item.Original)"
  if((Test-Path -LiteralPath $Origen) -and !(Test-Path -LiteralPath $Destino)){
    $Padre=Split-Path -Parent $Destino
    New-Item -ItemType Directory -Force -Path $Padre | Out-Null
    Move-Item -LiteralPath $Origen -Destination $Destino
    $Movidos++
    Write-Host "ROLLBACK_OK: $Origen -> $Destino"
  }else{
    Write-Host "ROLLBACK_SKIP: $Origen"
  }
}
Write-Host "[RESULTADO] RollbackMovidos=$Movidos"
