# FIX_TORCH_RESUME_V2.ps1 - Reanuda hasta completar 2.4GB
$ErrorActionPreference="Continue"
Set-Location C:\RUNEFORGE_V2_CORE

$whlUrl = "https://download.pytorch.org/whl/cu121/torch-2.5.1%2Bcu121-cp311-cp311-win_amd64.whl"
$whlPath = "C:\RUNEFORGE_V2_CORE\torch-2.5.1+cu121-cp311-cp311-win_amd64.whl"
$expectedMinBytes = 2400000000  # 2.4GB minimo valido

Write-Host "--- FIX TORCH RESUME V2 ---" -ForegroundColor Cyan
taskkill /F /IM python.exe 2>$null

# Funcion para bajar con resume loop
function Download-WithResume {
    param($Url, $Path)
    $attempt=0
    while($true){
        $attempt++
        $size=0
        if(Test-Path $Path){ $size=(Get-Item $Path).Length }
        $sizeMB=[math]::Round($size/1MB,1)
        Write-Host "[Intento $attempt] Ya tienes $sizeMB MB / 2449 MB" -ForegroundColor Yellow

        if($size -ge $expectedMinBytes){
            Write-Host "[OK] Archivo completo $sizeMB MB" -ForegroundColor Green
            return $true
        }

        Write-Host "Descargando/reanudando con curl (puede tardar 40-60min en tu conexion)..." -ForegroundColor Gray
        # -C - = reanudar, --retry 20, --retry-delay 10
        curl.exe -L -C - -o "$Path" "$Url" --retry 20 --retry-delay 10 --connect-timeout 30
        
        Start-Sleep 2
        if(!(Test-Path $Path)){
            Write-Host "[WARN] Aun no existe, reintentando..." -ForegroundColor Red
            continue
        }
        $newSize=(Get-Item $Path).Length
        if($newSize -eq $size -and $newSize -lt $expectedMinBytes){
            Write-Host "[WARN] No avanzo, esperando 10s y reintentando..." -ForegroundColor Red
            Start-Sleep 10
        }
        # Si ya completo, sale
        if($newSize -ge $expectedMinBytes){ return $true }
    }
}

$ok = Download-WithResume -Url $whlUrl -Path $whlPath

if(-not $ok){
    Write-Host "[FAIL] No se completo" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/3] Instalando torch offline..." -ForegroundColor Yellow
# Instalacion limpia sin -ErrorAction mal puesto
python -m pip install "$whlPath" --no-deps --force-reinstall

Write-Host "[3/3] Instalando torchvision/torchaudio chiquitos..." -ForegroundColor Yellow
python -m pip install torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

Write-Host ""
Write-Host "[CHECK]" -ForegroundColor Cyan
python -c "import torch; print('CUDA disponible:', torch.cuda.is_available()); print('Version:', torch.__version__); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NO CUDA');"

Write-Host ""
Write-Host "[TIP] Si ya dice CUDA True, borra el .whl: Remove-Item C:\RUNEFORGE_V2_CORE\*.whl -Force" -ForegroundColor Green
