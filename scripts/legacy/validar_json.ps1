param([Parameter(Mandatory=$true)][string]$JsonPath)
$content = Get-Content $JsonPath -Raw -Encoding UTF8
$null = $content | ConvertFrom-Json
Write-Host "JSON válido: $JsonPath" -ForegroundColor Green
