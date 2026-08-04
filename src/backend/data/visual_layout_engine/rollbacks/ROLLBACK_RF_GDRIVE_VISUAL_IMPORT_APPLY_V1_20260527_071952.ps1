$ErrorActionPreference="Stop"
$Manifest="C:\RUNEFOGE_PRO\runeforge\data\visual_layout_engine\imports\gdrive_zod\apply\rf_gdrive_visual_import_apply_20260527_071952.json"
$Rows=@(Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json)
foreach($R in ($Rows | Where-Object {$_.Status -eq "COPIED"})){ if(Test-Path -LiteralPath $R.Destino){ Remove-Item -LiteralPath $R.Destino -Force } }
Write-Host "ROLLBACK_RF_GDRIVE_VISUAL_IMPORT_APPLY_V1_DONE"
