$ppssppExe=@("C:\Program Files\PPSSPP\PPSSPPWindows64.exe","$env:LOCALAPPDATA\Programs\PPSSPP\PPSSPPWindows64.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $ppssppExe) { Write-Host "PPSSPP no encontrado"; exit 1 }
Start-Process $ppssppExe
Get-Process PPSSPP* -ErrorAction SilentlyContinue | Select-Object ProcessName,Id
