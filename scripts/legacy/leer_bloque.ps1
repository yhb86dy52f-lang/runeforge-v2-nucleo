param([Parameter(Mandatory=$true)][string]$BlockPath)
Get-Content $BlockPath -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }
