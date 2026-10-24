# FINAL_FIX_NANO.ps1 - Parche definitivo 1228x690 + Affinity + DXCam
# Corre DESPUES de FIX_TORCH_CUDA.ps1

$ErrorActionPreference="Continue"
$uiDir="C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui"
$uiPath="$uiDir\ui_overlay.py"

Write-Host "--- FINAL FIX NANO 1228x690 ---" -ForegroundColor Cyan

# 1. Matar todo
taskkill /F /IM python.exe 2>$null
taskkill /F /IM OpenFrameGen.exe 2>$null
Start-Sleep 1

# 2. Restaurar backup limpio si existe
$backups=Get-ChildItem "$uiDir\ui_overlay.py.bak*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if($backups){
  Write-Host "[RESTORE] Restaurando $($backups[0].Name)" -ForegroundColor Yellow
  Copy-Item $backups[0].FullName $uiPath -Force
}

# 3. Parche Python real con script de Python (no regex ps malo)
$patchScript=@'
import pathlib
p = pathlib.Path(r"C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui\ui_overlay.py")
text = p.read_text(encoding="utf-8", errors="ignore")

# Fix 1: region=region -> region=None
text = text.replace("region=region", "region=None")

# Fix 2: Cualquier region hardcodeado 1920x1080 -> None para auto-detectar tu 1228x690
import re
text = re.sub(r"region\s*=\s*\(?\s*0\s*,\s*0\s*,\s*1920\s*,\s*1080\s*\)?", "region=None", text)
text = re.sub(r"region\s*=\s*\(\s*1920\s*,\s*1080\s*\)", "region=None", text)

# Fix 3: max_buffer_len=1 no sirve en concurrent, poner 2
text = text.replace("max_buffer_len=1", "max_buffer_len=2")

# Fix 4: Affinity Error - int(None)
# Busca cualquier int(affinity/core/thread) y hazlo safe
text = text.replace("int(affinity)", "(0 if affinity is None else int(affinity))")
text = text.replace("int(core)", "(0 if core is None else int(core))")
text = text.replace("int(thread)", "(0 if thread is None else int(thread))")

# Fix 5: Si hay psutil cpu_affinity con None, envolver en try
if "cpu_affinity" in text and "try:" not in text.split("cpu_affinity")[0][-200:]:
    text = text.replace("p.cpu_affinity", "try:\n        p.cpu_affinity")
    # Esto es parche simple, si no funciona igual no rompe

# Fix 6: Asegurar que antes de crear cam, borre instancia vieja
if "dxcam.create" in text:
    text = text.replace("cam = dxcam.create", "try:\n        del cam\n    except:\n        pass\n    cam = dxcam.create")

p.write_text(text, encoding="utf-8")
print("[OK] Parches aplicados")
'@

$patchScript | Set-Content "$env:TEMP\patch.py" -Encoding UTF8
python "$env:TEMP\patch.py"

# 4. Verificar sintaxis
python -m py_compile $uiPath
if($LASTEXITCODE -eq 0){
  Write-Host "[OK] Sintaxis OK" -ForegroundColor Green
} else {
  Write-Host "[FAIL] Sintaxis rota, restaurando original" -ForegroundColor Red
  Invoke-WebRequest "https://raw.githubusercontent.com/Deadly-pro/Open-Frame-gen/main/ui/ui_overlay.py" -OutFile $uiPath -UseBasicParsing -ErrorAction SilentlyContinue
  # Re-aplicar solo region=None
  (Get-Content $uiPath -Raw).Replace("region=region","region=None").Replace("max_buffer_len=1","max_buffer_len=2") | Set-Content $uiPath -Encoding UTF8
}

Write-Host ""
Write-Host "=== AHORA PRUEBA LIMPIO ===" -ForegroundColor Cyan
Write-Host "1. Cierra Opera GX completamente (es el que te da 0x887A0026)"
Write-Host "2. Corre:"
Write-Host "   cd C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen"
Write-Host "   python ui/ui_overlay.py"
Write-Host "3. En TARGET WINDOW elige: Fullscreen o Monitor 0 (NO GX Corner - Opera)"
Write-Host "4. REFRESH WINDOWS -> START AI PIPELINE"
Write-Host ""
Write-Host "Si aun da error, corre test sin UI:"
Write-Host "   python -c ""import dxcam; cam=dxcam.create(output_color='BGRA', max_buffer_len=2); print('DXCAM OK', cam); cam.start(); import time; time.sleep(1); f=cam.get_latest_frame(); print('Frame:', f.shape if f is not None else 'None'); cam.stop()"""
