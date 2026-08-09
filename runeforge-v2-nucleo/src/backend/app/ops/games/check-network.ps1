Write-Host '=== CHECK NETWORK ==='
Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
Where-Object {
    $_.IPAddress -notlike '127.*' -and
    $_.IPAddress -notlike '169.254*'
} |
Select-Object InterfaceAlias, IPAddress |
Format-Table -AutoSize
