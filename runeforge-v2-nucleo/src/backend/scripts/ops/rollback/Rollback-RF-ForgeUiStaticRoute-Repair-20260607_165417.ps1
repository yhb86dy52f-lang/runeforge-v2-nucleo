$ErrorActionPreference="Stop"
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$AppJs="C:\RUNEFOGE_PRO\runeforge\app\src\app.js"
$RollbackSource="C:\RUNEFOGE_PRO\runeforge\data\backups\forge_ui_static_route\20260607_165043\app.js.20260607_165043.bak"
if(!(Test-Path -LiteralPath $RollbackSource)){throw "NO_EXISTE_ROLLBACK_SOURCE: $RollbackSource"}
Copy-Item -LiteralPath $RollbackSource -Destination $AppJs -Force
node --check $AppJs
pm2 restart runeforge-mvp --update-env
Start-Sleep -Seconds 3
Invoke-RestMethod "http://127.0.0.1:3100/health" -TimeoutSec 5 | ConvertTo-Json -Depth 4
