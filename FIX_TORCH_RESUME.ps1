# FIX_TORCH_RESUME.ps1 - Para internet inestable (2.4GB)
# Usa BITS que si se corta, reanuda solo. No usa pip para descargar.

$ErrorActionPreference="Continue"
Set-Location C:\RUNEFORGE_V2_CORE
$whlUrl = "https://download.pytorch.org/whl/cu121/torch-2.5.1%2Bcu121-cp311-cp311-win_amd64.whl"
$whlPath = "C:\RUNEFORGE_V2_CORE\torch-2.5.1+cu121-cp311-cp311-win_amd64.whl"
$visionUrl = "https://download.pytorch.org/whl/cu121/torchvision-0.20.1%2Bcu121-cp311-cp311-win_amd64.whl"
$visionPath = "C:\RUNEFORGE_V2_CORE\torchvision-0.20.1+cu121-cp311-cp311-win_amd64.whl"
$audioUrl = "https://download.pytorch.org/whl/cu121/torchaudio-2.5.1%2Bcu121-cp311-cp311-win_amd64.whl"
$audioPath = "C:\RUNEFORGE_V2_CORE\torchaudio-2.5.1+cu121-cp311-cp311-win_amd64.whl"

Write-Host "[1/4] Matando pythons..." -ForegroundColor Yellow
taskkill /F /IM python.exe 2>$null

Write-Host "[2/4] Bajando torch 2.5.1+cu121 (2.4GB) con BITS - si se corta, vuelve a correr este mismo script" -ForegroundColor Yellow
Write-Host "URL: $whlUrl" -ForegroundColor Gray

# BITS es nativo de Windows y reanuda solo
try {
    # Limpiar job viejo
    Get-BitsTransfer -Name "torch-cuda" -ErrorAction SilentlyContinue | Remove-BitsTransfer -ErrorAction SilentlyContinue
    Start-BitsTransfer -Source $whlUrl -Destination $whlPath -DisplayName "torch-cuda" -Description "RUNEFORGE torch 2.4GB" -ErrorAction Stop
    Write-Host "[OK] Torch bajado: $whlPath" -ForegroundColor Green
} catch {
    Write-Host "[WARN] BITS fallo, probando con curl resume..." -ForegroundColor Yellow
    # curl con resume
    curl.exe -L -C - -o "$whlPath" "$whlUrl" --retry 10 --retry-delay 5
}

if(!(Test-Path $whlPath) -or (Get-Item $whlPath).Length -lt 100MB){
    Write-Host "[FAIL] No se pudo bajar completo. Vuelve a correr este script, BITS reanuda donde se quedo" -ForegroundColor Red
    Write-Host "Tip: Conectate por cable ethernet, cierra Opera GX y no uses VPN"
    exit 1
}

Write-Host "[3/4] Bajando torchvision y torchaudio (chicos, 6MB y 4MB)..." -ForegroundColor Yellow
try { Start-BitsTransfer -Source $visionUrl -Destination $visionPath -ErrorAction SilentlyContinue } catch { curl.exe -L -o "$visionPath" "$visionUrl" --retry 5 }
try { Start-BitsTransfer -Source $audioUrl -Destination $audioPath -ErrorAction SilentlyContinue } catch { curl.exe -L -o "$audioPath" "$audioUrl" --retry 5 }

Write-Host "[4/4] Instalando offline..." -ForegroundColor Yellow
python -m pip install --no-index --no-deps "$whlPath"
python -m pip install --no-index --no-deps "$visionPath" "$audioPath" -ErrorAction SilentlyContinue
# Si faltan deps, pip las baja chicas
python -m pip install torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 --no-deps -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[CHECK]" -ForegroundColor Cyan
python -c "import torch; print('CUDA:', torch.cuda.is_available()); print('Version:', torch.__version__); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NO'); print('CUDA ver:', torch.version.cuda)"

Write-Host ""
Write-Host "[OK] Si dice CUDA True y 1660 SUPER, borra los .whl para liberar espacio:" -ForegroundColor Green
Write-Host "Remove-Item C:\RUNEFORGE_V2_CORE\*.whl -Force"
