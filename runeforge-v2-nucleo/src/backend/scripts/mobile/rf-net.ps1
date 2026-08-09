$ErrorActionPreference="SilentlyContinue"
$ts=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[RF_NET][$ts]" -ForegroundColor Cyan
tailscale status
Write-Host "--- IP ---"
Get-NetIPConfiguration | Select-Object InterfaceAlias,@{n="IPv4";e={$_.IPv4Address.IPAddress -join ","}},@{n="Gateway";e={$_.IPv4DefaultGateway.NextHop -join ","}},@{n="DNS";e={$_.DNSServer.ServerAddresses -join ","}} | Format-Table -AutoSize
