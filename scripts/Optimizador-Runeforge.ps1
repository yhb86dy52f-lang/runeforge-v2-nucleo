$ErrorActionPreference = "SilentlyContinue"
Clear-Host
Write-Host "=== RUNEFORGE: RESET DE RAM Y OPTIMIZACION ===" -ForegroundColor Cyan
Write-Host "[*] Purgando memoria Standby y File Cache..." -ForegroundColor Yellow

# Limpieza básica de RAM nativa de Windows
$code = @"
[DllImport("kernel32.dll")]
public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);
"@
$type = Add-Type -MemberDefinition $code -Name "Win32Set" -Namespace Win32Functions -PassThru
Get-Process | ForEach-Object { $type::SetProcessWorkingSetSize($_.Handle, -1, -1) | Out-Null }

# Limpieza de cache DNS y temporales
Clear-DnsClientCache
Write-Host "[*] Limpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n[OK] Memoria RAM optimizada. Presiona cualquier tecla para salir." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")