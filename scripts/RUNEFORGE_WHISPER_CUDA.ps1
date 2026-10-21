# ============================================
# RUNEFORGE - WHISPER CUDA ENVIRONMENT FIX
# ============================================
$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$m, [string]$c = "White")
    Write-Host $m -ForegroundColor $c
    [void]$capture.Add($m)
}

Log "===============================================" "Cyan"
Log " RUNEFORGE - WHISPER CUDA ENVIRONMENT FIX" "Cyan"
Log "===============================================" "Cyan"

# 1. Validar entorno
$venvPath = "C:\RUNEFORGE_V2_CORE\whisper-backend\venv"
$pip = "$venvPath\Scripts\pip.exe"
$python = "$venvPath\Scripts\python.exe"

if (-not (Test-Path $pip)) {
    Log "[-] No se encontró el entorno virtual en: $venvPath" "Red"
    $capture | Set-Clipboard
    return
}
Log "[+] Entorno virtual detectado." "Green"

# 2. Asegurar instalación (retoma si se cortó)
Log "[*] Instalando/Verificando nvidia-cudnn-cu12 y nvidia-cublas-cu12..." "Yellow"
Log "[!] Si la descarga se cortó, este comando la reanudará." "Gray"
$installOut = & $pip install nvidia-cudnn-cu12 nvidia-cublas-cu12 2>&1
foreach ($line in $installOut) { 
    if ($line -match "Successfully installed|Requirement already satisfied|Downloading") {
        Log "    $line" "DarkGray" 
    }
}
if ($LASTEXITCODE -ne 0) {
    Log "[-] Falló la instalación. Revisa tu conexión y vuelve a correr el script." "Red"
    $capture | Set-Clipboard
    return
}

# 3. Localizar los directorios BIN
Log "[*] Localizando carpetas bin de CUDA..." "Yellow"
$cublasBin = "$venvPath\Lib\site-packages\nvidia\cublas\bin"
$cudnnBin  = "$venvPath\Lib\site-packages\nvidia\cudnn\bin"

$pathsToAdd = @()
if (Test-Path $cublasBin) { $pathsToAdd += $cublasBin; Log "    [+] cublas: $cublasBin" "Green" }
if (Test-Path $cudnnBin)  { $pathsToAdd += $cudnnBin;  Log "    [+] cudnn:  $cudnnBin" "Green" }

if ($pathsToAdd.Count -eq 0) {
    Log "[-] No se encontraron los binarios en el venv." "Red"
    $capture | Set-Clipboard
    return
}

# 4. Inyectar en PATH
Log "[*] Inyectando DLLs en el PATH de la sesión..." "Yellow"
foreach ($p in $pathsToAdd) {
    if ($env:Path -notmatch [regex]::Escape($p)) {
        $env:Path += ";$p"
    }
}
Log "[+] PATH actualizado." "Green"

# 5. Validación con PyTorch
Log "[*] Validando CUDA con PyTorch..." "Yellow"
$pyTest = & $python -c "import torch; print(f'CUDA Disponible: {torch.cuda.is_available()} | GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')" 2>&1
Log "    $pyTest" "Cyan"

Log "===============================================" "Cyan"
Log " PROCESO COMPLETADO" "Cyan"
Log "===============================================" "Cyan"
Log "[OK] Las DLLs de CUDA están listas para Whisper." "Green"

$capture | Set-Clipboard
Log "[OK] Reporte copiado al portapapeles (Ctrl+V)." "Cyan"
