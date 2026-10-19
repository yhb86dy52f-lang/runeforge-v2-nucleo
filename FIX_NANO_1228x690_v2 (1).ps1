# FIX_NANO_1228x690_v2.ps1 - Parche definitivo para monitor 1228x690
$ErrorActionPreference="Continue"
$uiPath="C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui\ui_overlay.py"
if(!(Test-Path $uiPath)){ Write-Host "[FAIL] No existe $uiPath"; exit 1 }
Copy-Item $uiPath "$uiPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
Write-Host "[OK] Backup creado"

# Lee contenido
$lines=Get-Content $uiPath

# Parche línea por línea
$newLines=@()
foreach($line in $lines){
  # Fix 1: dxcam.create con region -> region=None para auto-detectar tu 1228x690
  if($line -match "dxcam\.create\(.*region=region"){
    $newLines+=$line -replace "region=region","region=None # RUNEFORGE FIX 1228x690 auto"
  } elseif($line -match "dxcam\.create\(.*region=.*\)"){
    # Si ya tiene otra region, forzar None
    if($line -notmatch "region=None"){ 
      $newLines+=$line -replace "region=[^,]+","region=None"
    } else { $newLines+=$line }
  } else {
    # Fix 2: int(affinity) cuando affinity es None
    $fixed=$line -replace "int\(([^)]+)\)","(int(`$1) if `$1 is not None else 0)"
    # Pero esa regex es para ps, para python necesitamos diferente, hacemos directo
    $fixed=$line
    if($line -match "int\(.*affinity.*\)"){ $fixed=$line -replace "int\((.*?)\)","(int(`$1) if `$1 is not None else 0)" }
    $newLines+=$fixed
  }
}

# Parche Python directo más simple: reemplazo final global
$content=$newLines -join "`n"
# Fuerza region=None en cualquier llamada dxcam.create
$content=$content -replace "region=region","region=None"
# Fix affinity: busca int\( y si es affinity o core
$content=$content -replace "int\(affinity\)","(0 if affinity is None else int(affinity))"
$content=$content -replace "int\(core\)","(0 if core is None else int(core))"
$content=$content -replace "int\(thread\)","(0 if thread is None else int(thread))"

# Guarda
Set-Content -Path $uiPath -Value $content -Encoding UTF8
Write-Host "[OK] ui_overlay.py parcheado para 1228x690"
Write-Host ""
Write-Host "Ahora prueba:"
Write-Host "cd C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen"
Write-Host "python ui/ui_overlay.py"
Write-Host ""
Write-Host "Si aún dice Invalid Region, corre este modo simple sin región:"
Write-Host "python -c `"import dxcam; cam=dxcam.create(output_color='BGRA'); print('DXCAM OK', cam); cam.start(); import time; time.sleep(2); print(cam.get_latest_frame()); cam.stop()`""
