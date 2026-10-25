param([Parameter(Mandatory)][string]$Path, [ValidateSet('1h','24h','72h')][string]$Ttl = '72h')
$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

if (-not (Test-Path $Path)) { Log "ERROR: no existe $Path"; $capture | Set-Clipboard; return }

$url = curl.exe -s -F "reqtype=fileupload" -F "time=$Ttl" -F "fileToUpload=@$Path" https://litterbox.catbox.moe/resources/internals/api.php
if ([string]::IsNullOrWhiteSpace($url) -or $url -notmatch '^https?://') {
    Log "ERROR: respuesta invalida de litterbox -> $url"
} else {
    Log $url
}

$capture | Set-Clipboard
