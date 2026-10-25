[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$tempLog = "$env:TEMP\scratch_output.txt"
Start-Transcript -Path $tempLog -Force | Out-Null
try {

pwd

} catch { $_ } finally {
    Stop-Transcript | Out-Null
    if (Test-Path $tempLog) { Get-Content $tempLog -Raw | Set-Clipboard }
}
