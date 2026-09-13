$report = New-Object System.Collections.Generic.List[string]
$report.Add("--- RUNEFORGE V2.6.2 STATUS REPORT ---")
$report.Add("Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

$services = @{
    "Ollama (LLM)"     = "http://127.0.0.1:11434/api/tags"
    "Fastify Backend" = "http://127.0.0.1:3001/health"
}

foreach ($s in $services.Keys) {
    try {
        $res = Invoke-RestMethod -Uri $services[$s] -TimeoutSec 2 -ErrorAction Stop
        $report.Add("[$s]: ONLINE")
    } catch {
        $report.Add("[$s]: OFFLINE")
    }
}

$pm2Check = pm2 list 2>&1
if ($LASTEXITCODE -eq 0) { $report.Add("[PM2 Supervisor]: ONLINE") } else { $report.Add("[PM2 Supervisor]: REVISAR") }

$tsExe = "C:\Program Files\Tailscale\tailscale.exe"
if (Test-Path $tsExe) {
    $tsStatus = & $tsExe status 2>&1
    if ($LASTEXITCODE -eq 0) { $report.Add("[Tailscale Mesh]: ONLINE") } else { $report.Add("[Tailscale Mesh]: OFFLINE") }
} else {
    $report.Add("[Tailscale Mesh]: NO INSTALADO")
}

$output = $report -join "`n"
$output | Set-Clipboard

Clear-Host
Write-Host "--- RUNEFORGE REPORT ---" -ForegroundColor Cyan
Write-Host $output
Write-Host "------------------------" -ForegroundColor Cyan
Write-Host "[OK] Reporte copiado automáticamente al portapapeles (Ctrl+V)." -ForegroundColor Green

function Prompt {
    $time = Get-Date -Format "HH:mm:ss"
    $date = Get-Date -Format "yyyy-MM-dd"
    Write-Host "┌──[" -NoNewline -ForegroundColor DarkGray
    Write-Host "📅 $date " -NoNewline -ForegroundColor Cyan
    Write-Host "🕒 $time" -NoNewline -ForegroundColor Yellow
    Write-Host "]─[" -NoNewline -ForegroundColor DarkGray
    Write-Host "⚡ RUNEFORGE" -NoNewline -ForegroundColor Magenta
    Write-Host "]" -ForegroundColor DarkGray
    Write-Host "`n└─> " -NoNewline -ForegroundColor Green
    return " "
}
