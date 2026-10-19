# FINAL_FIX_NANO_V3.ps1 - Parche definitivo sin romper sintaxis
# Correlo DESPUES de que torch ya diga CUDA True

$ErrorActionPreference="Continue"
$uiPath="C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui\ui_overlay.py"

Write-Host "--- FINAL FIX V3 ---" -ForegroundColor Cyan
taskkill /F /IM python.exe 2>$null
Start-Sleep 1

# Backup
if(Test-Path $uiPath){
  Copy-Item $uiPath "$uiPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
  Write-Host "[OK] Backup creado"
}

# Python patcher seguro
@'
import pathlib, re
p = pathlib.Path(r"C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui\ui_overlay.py")
t = p.read_text(encoding="utf-8", errors="ignore")

# 1. region=None
t = t.replace("region=region", "region=None")

# 2. max_buffer_len 1 -> 2 (concurrent no soporta 1)
t = t.replace("max_buffer_len=1", "max_buffer_len=2")

# 3. Affinity fix - si hay int(affinity) con None, hazlo safe
t = re.sub(r"int\s*\(\s*affinity\s*\)", "(0 if affinity is None else int(affinity))", t)
t = re.sub(r"int\s*\(\s*core\s*\)", "(0 if core is None else int(core))", t)

# 4. Evitar DXCamera instance already exists
if "DXCamera instance already exists" not in t:
    t = t.replace("cam = dxcam.create", "try:\n    del cam\nexcept:\n    pass\ncam = dxcam.create")

p.write_text(t, encoding="utf-8")
print("Parche V3 aplicado")
'@ | Set-Content "$env:TEMP\patch_v3.py" -Encoding UTF8

python "$env:TEMP\patch_v3.py"
python -m py_compile $uiPath
if($LASTEXITCODE -eq 0){ Write-Host "[OK] Sintaxis OK" -ForegroundColor Green } else { Write-Host "[FAIL] Sintaxis" -ForegroundColor Red }

Write-Host ""
Write-Host "AHORA:"
Write-Host "1. Cierra Opera GX por completo"
Write-Host "2. cd C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen"
Write-Host "3. python ui/ui_overlay.py"
Write-Host "4. TARGET WINDOW = Fullscreen / Monitor 0, NO GX Corner"
