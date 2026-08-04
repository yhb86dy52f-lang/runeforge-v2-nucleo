$TaskName = "Runeforge.TerminalExportWatcher"

try {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
} catch {}

Get-CimInstance Win32_Process |
Where-Object {
    $_.CommandLine -like "*Watch-TerminalExport.ps1*"
} |
ForEach-Object {
    try {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    } catch {}
}

Write-Host "[OK] Watcher detenido si estaba activo." -ForegroundColor Green
