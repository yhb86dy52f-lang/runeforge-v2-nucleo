param([Parameter(Mandatory=$true)][string]$TxtPath)
$content = Get-Content $TxtPath -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }
$content | Set-Content $TxtPath -Encoding UTF8
Write-Host "TXT normalizado: $TxtPath"
