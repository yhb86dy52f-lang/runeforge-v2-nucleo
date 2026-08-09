$ErrorActionPreference="Stop"
Copy-Item -LiteralPath "C:\RUNEFOGE_PRO\runeforge\scripts\telemetria\Convert-TglTelemetryMarkdown-V1.ps1.backup_countfix_20260603_222857" -Destination "C:\RUNEFOGE_PRO\runeforge\scripts\telemetria\Convert-TglTelemetryMarkdown-V1.ps1" -Force
Write-Host "ROLLBACK_OK"
