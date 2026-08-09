$ErrorActionPreference = "Stop"

Write-Host "=== HEALTH ===" -ForegroundColor Cyan
Invoke-RestMethod http://localhost:3100/health | ConvertTo-Json -Depth 10

Write-Host "`n=== STATUS ===" -ForegroundColor Cyan
Invoke-RestMethod http://localhost:3100/status | ConvertTo-Json -Depth 10

Write-Host "`n=== FORGE ===" -ForegroundColor Cyan
Invoke-RestMethod http://localhost:3100/api/forge | ConvertTo-Json -Depth 10

Write-Host "`n=== CHAT (SYSTEM) ===" -ForegroundColor Cyan
Invoke-RestMethod -Method Post -Uri http://localhost:3100/api/chat -ContentType "application/json" -Body '{"message":"estado del sistema","module":"system","sessionId":"check-script"}' | ConvertTo-Json -Depth 10
