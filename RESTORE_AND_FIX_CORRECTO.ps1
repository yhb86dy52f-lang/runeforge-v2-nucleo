# RESTORE_AND_FIX_CORRECTO.ps1 - Arregla el SyntaxError que te dejé
$ErrorActionPreference="Continue"
$uiDir="C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui"
$uiPath="$uiDir\ui_overlay.py"

# 1. Restaura backup más reciente
$backups=Get-ChildItem "$uiDir\ui_overlay.py.bak*" | Sort-Object LastWriteTime -Descending
if($backups){
  $latest=$backups[0].FullName
  Write-Host "[RESTORE] Restaurando desde $latest"
  Copy-Item $latest $uiPath -Force
  Write-Host "[OK] Restaurado"
} else {
  Write-Host "[WARN] No hay backup, re-clonando archivo original"
  Invoke-WebRequest "https://raw.githubusercontent.com/Deadly-pro/Open-Frame-gen/main/ui/ui_overlay.py" -OutFile $uiPath -UseBasicParsing
}

# 2. Parche CORRECTO sin romper sintaxis
$content=Get-Content $uiPath -Raw

# Parche 1: region=region -> region=None (SIN comentario dentro de la linea)
$content=$content -replace "region=region","region=None"

# Parche 2: Si aún hay region con algo raro, forzar None solo en dxcam.create
$content=$content -replace "dxcam\.create\s*\(\s*region\s*=\s*[^,\)]+","dxcam.create(region=None"

# Parche 3: Fix Affinity int(None) -> safe
$content=$content -replace "int\(affinity\)","int(affinity) if affinity is not None else 0"
$content=$content -replace "int\(core\)","int(core) if core is not None else 0"
$content=$content -replace "affinity = int\(","affinity = (0 if affinity is None else int("
# Fix genérico para cualquier int(None)
$content=$content -replace "int\((\w+)\)\s*if\s*\1 is not None else 0","(0 if `$1 is None else int(`$1))" # placeholder

# Guarda limpio
Set-Content -Path $uiPath -Value $content -Encoding UTF8

# Verificación de sintaxis
Write-Host "[CHECK] Verificando sintaxis..."
python -m py_compile $uiPath
if($LASTEXITCODE -eq 0){ Write-Host "[OK] Sintaxis OK - ya no hay '(' never closed" }
else { Write-Host "[FAIL] Aún hay error de sintaxis"; exit 1 }

Write-Host ""
Write-Host "[OK] Parche correcto aplicado"
Write-Host "Ahora:"
Write-Host "cd $uiDir\.."
Write-Host "python ui/ui_overlay.py"
