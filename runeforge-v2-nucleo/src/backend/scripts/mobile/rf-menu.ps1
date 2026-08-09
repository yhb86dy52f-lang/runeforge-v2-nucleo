function Show-Menu {
Clear-Host
Write-Host "--- RUNEFORGE MOBILE CONSOLE ---" -ForegroundColor Green
Write-Host "1) Health"
Write-Host "2) PM2 status"
Write-Host "3) Logs"
Write-Host "4) Network/Tailscale"
Write-Host "5) Runeforge status JSON"
Write-Host "6) Clear"
Write-Host "0) Exit"
}
do {
Show-Menu
$op=Read-Host "Opcion"
switch($op){
 "1" { & "C:\RUNEFOGE_PRO\runeforge\scripts\mobile\rf-health.ps1"; pause }
 "2" { & "C:\RUNEFOGE_PRO\runeforge\scripts\mobile\rf-pm2.ps1"; pause }
 "3" { & "C:\RUNEFOGE_PRO\runeforge\scripts\mobile\rf-logs.ps1"; pause }
 "4" { & "C:\RUNEFOGE_PRO\runeforge\scripts\mobile\rf-net.ps1"; pause }
 "5" { & "C:\RUNEFOGE_PRO\runeforge\scripts\mobile\rf-status.ps1"; pause }
 "6" { Clear-Host }
}
} while($op -ne "0")
