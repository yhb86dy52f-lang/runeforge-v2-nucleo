# --- RUNEFORGE V2.6.2 STATUS REPORT ---
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "`n--- RUNEFORGE REPORT ---" -ForegroundColor Yellow
Write-Host "--- RUNEFORGE V2.6.2 STATUS REPORT ---" -ForegroundColor Yellow
Write-Host "Timestamp: $ts"

function Test-Url($url) {
    try {
        Invoke-RestMethod $url -TimeoutSec 3 | Out-Null
        return "ONLINE"
    } catch { return "OFFLINE" }
}

$ollama = Test-Url "http://127.0.0.1:11434/api/tags"
$backend = Test-Url "http://127.0.0.1:3100/healthz"
if ($backend -eq "OFFLINE") { $backend = Test-Url "http://127.0.0.1:3100/health" }

$pm2 = "OFFLINE"
try {
    $json = pm2 jlist 2>$null | ConvertFrom-Json
    if ($json | Where-Object { $_.name -like "*runeforge*" -and $_.pm2_env.status -eq "online" }) { $pm2 = "ONLINE" }
    elseif ($json.Count -gt 0) { $pm2 = "ONLINE" }
} catch {
    try { pm2 list 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { $pm2 = "ONLINE" } } catch {}
}

$tailscale = "OFFLINE"
try { tailscale status --peers=false 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { $tailscale = "ONLINE" } } catch {}

function Write-Status($label, $status) {
    $color = if ($status -eq "ONLINE") { "Green" } else { "Red" }
    Write-Host "[$label]: " -NoNewline; Write-Host $status -ForegroundColor $color
}

Write-Status "Ollama (LLM)" $ollama
Write-Status "Fastify Backend" $backend
Write-Status "PM2 Supervisor" $pm2
Write-Status "Tailscale Mesh" $tailscale

$report = @"
--- RUNEFORGE REPORT ---
--- RUNEFORGE V2.6.2 STATUS REPORT ---
Timestamp: $ts
[Ollama (LLM)]: $ollama
[Fastify Backend]: $backend
[PM2 Supervisor]: $pm2
[Tailscale Mesh]: $tailscale

"@

Write-Host "------------------------"
$report | Set-Clipboard
Write-Host "[OK] Reporte copiado automaticamente al portapapeles (Ctrl+V)." -ForegroundColor Cyan
Write-Host $report