# FIX_TORCH_CUDA.ps1 - Fix definitivo CUDA para GTX 1660 SUPER
# NO COPIES COMANDOS A MANO, solo corre este ps1

$ErrorActionPreference="Continue"
Set-Location C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen

Write-Host "[1/3] Matando pythons colgados..." -ForegroundColor Yellow
taskkill /F /IM python.exe 2>$null
Start-Sleep -Seconds 1

Write-Host "[2/3] Desinstalando torch CPU..." -ForegroundColor Yellow
# Usamos python -m pip para evitar problemas de PATH
python -m pip uninstall torch torchvision torchaudio -y

Write-Host "[3/3] Instalando torch CUDA 12.1 para tu 1660 SUPER..." -ForegroundColor Yellow
# Este es el que jala para tu tarjeta, 2GB aprox
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

Write-Host ""
Write-Host "[CHECK] Verificando CUDA..." -ForegroundColor Cyan
python -c "import torch; print('CUDA disponible:', torch.cuda.is_available()); print('Version:', torch.__version__); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NO CUDA - reinstala'); print('CUDA Version torch:', torch.version.cuda if torch.cuda.is_available() else 'N/A')"

Write-Host ""
Write-Host "[OK] Si dice CUDA disponible: True y GTX 1660 SUPER, ya quedo" -ForegroundColor Green
Write-Host "Si dice False, cierra todo y vuelve a correr este ps1 como Admin"
