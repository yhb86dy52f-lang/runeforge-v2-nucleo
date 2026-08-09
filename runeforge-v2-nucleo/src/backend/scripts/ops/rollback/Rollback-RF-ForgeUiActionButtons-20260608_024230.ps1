$ErrorActionPreference="Stop"
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$PanelFile="C:\RUNEFOGE_PRO\runeforge\app\public\forge\index.html"
$BackupPanel="C:\RUNEFOGE_PRO\runeforge\data\backups\forge_ui_action_buttons\20260608_024230\index.html.before_action_buttons.20260608_024230.bak"
if(!(Test-Path -LiteralPath $BackupPanel)){throw "NO_EXISTE_BACKUP: $BackupPanel"}
Copy-Item -LiteralPath $BackupPanel -Destination $PanelFile -Force
Write-Host "ROLLBACK_OK: $PanelFile"
