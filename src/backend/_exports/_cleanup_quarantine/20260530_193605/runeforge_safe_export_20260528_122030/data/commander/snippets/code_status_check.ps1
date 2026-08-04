# RUNEFORGE STATUS CHECK
# No modifica nada.

$Root = "C:\RUNEFOGE_PRO\runeforge"
$Backend = Join-Path $Root "app"

[ordered]@{
    root_exists = Test-Path $Root
    backend_exists = Test-Path $Backend
    docs_exists = Test-Path (Join-Path $Root "docs")
    data_exists = Test-Path (Join-Path $Root "data")
    scripts_exists = Test-Path (Join-Path $Root "scripts")
    node = try { node -v } catch { "NO_NODE" }
    npm = try { npm -v } catch { "NO_NPM" }
    pm2 = try { pm2 -v } catch { "NO_PM2" }
    tailscale = try { tailscale status } catch { "NO_TAILSCALE" }
} | ConvertTo-Json -Depth 5

Write-Host "`n[OK] Estado rápido Runeforge generado." -ForegroundColor Green
