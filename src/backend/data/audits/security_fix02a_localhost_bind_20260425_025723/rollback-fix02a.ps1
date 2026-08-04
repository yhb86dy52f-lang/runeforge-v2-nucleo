Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Copy-Item -LiteralPath "C:\RUNEFOGE_PRO\runeforge\backups\security\server.js.20260425_025723.fix02a.bak" -Destination "C:\RUNEFOGE_PRO\runeforge\app\src\server.js" -Force
Copy-Item -LiteralPath "C:\RUNEFOGE_PRO\runeforge\backups\security\env.js.20260425_025723.fix02a.bak" -Destination "C:\RUNEFOGE_PRO\runeforge\app\src\config\env.js" -Force

if (Test-Path -LiteralPath "C:\RUNEFOGE_PRO\runeforge\backups\security\.env.example.20260425_025723.fix02a.bak") {
    Copy-Item -LiteralPath "C:\RUNEFOGE_PRO\runeforge\backups\security\.env.example.20260425_025723.fix02a.bak" -Destination "C:\RUNEFOGE_PRO\runeforge\app\.env.example" -Force
}

Push-Location "C:\RUNEFOGE_PRO\runeforge\app"
try {
    $raw = pm2 jlist 2>$null
    if ($raw) {
        $apps = $raw | ConvertFrom-Json
        $target = @($apps | Where-Object { $_.name -eq "runeforge" -or $_.pm2_env.pm_cwd -eq "C:\RUNEFOGE_PRO\runeforge\app" } | Select-Object -First 1)
        if ($target) {
            pm2 restart $target.name --update-env
        }
    }
} finally {
    Pop-Location
}

Write-Host "[ROLLBACK_FIX02A_OK]" -ForegroundColor Yellow
