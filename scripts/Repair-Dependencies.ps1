# ==============================================================================
# SCRIPT INTERNO: INSTALADOR DE DEPENDENCIAS
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$Message, [string]$Color = "Gray")
    Write-Host $Message -ForegroundColor $Color
    $null = $capture.Add($Message)
}

Log "╔══════════════════════════════════════════════════════╗" "Cyan"
Log "║   REPARACIÓN DE DEPENDENCIAS - RUNEFORGE CORE        ║" "Cyan"
Log "╚══════════════════════════════════════════════════════╝" "Cyan"
Log ""

# ---------------------------------------------------------
# 1. Reparar Whisper Backend (pip install)
# ---------------------------------------------------------
$WhisperDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$WhisperPy  = "$WhisperDir\venv\Scripts\python.exe"

if (Test-Path $WhisperPy) {
    Log "[*] Instalando 'faster-whisper' en el entorno virtual..." "Yellow"
    $reqFile = "$WhisperDir\requirements.txt"
    if (Test-Path $reqFile) {
        Log "    -> Encontrado requirements.txt. Instalando todo..." "DarkGray"
        $proc = Start-Process -FilePath $WhisperPy -ArgumentList "-m pip install -r `"$reqFile`"" -Wait -NoNewWindow -PassThru
    } else {
        Log "    -> Instalando 'faster-whisper' y 'torch' (por defecto)..." "DarkGray"
        $proc = Start-Process -FilePath $WhisperPy -ArgumentList "-m pip install faster-whisper torch" -Wait -NoNewWindow -PassThru
    }
    if ($proc.ExitCode -eq 0) { Log "    [OK] Whisper dependencias instaladas." "Green" } 
    else { Log "    [X] Error al instalar Whisper. Revisa la consola." "Red" }
} else {
    Log "    [!] No se encontró python.exe en el venv de Whisper." "Red"
}

# ---------------------------------------------------------
# 2. Reparar Nexus Brain (psutil)
# ---------------------------------------------------------
Log "`n[*] Instalando 'psutil' para Nexus Brain..." "Yellow"
$brainProc = Start-Process -FilePath "python" -ArgumentList "-m pip install psutil" -Wait -NoNewWindow -PassThru
if ($brainProc.ExitCode -eq 0) { Log "    [OK] psutil instalado en Python global." "Green" } 
else { Log "    [X] Error al instalar psutil." "Red" }

# ---------------------------------------------------------
# 3. Reparar Nexus Tactical (npm install)
# ---------------------------------------------------------
$TauriDir = "C:\RUNEFORGE_V2_CORE\nexus-tactical"
if (Test-Path $TauriDir) {
    Log "`n[*] Instalando dependencias de Node.js en Nexus Tactical..." "Yellow"
    Log "    (Esto puede tardar unos minutos dependiendo de tu HDD)..." "DarkGray"
    $npmProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm install" -WorkingDirectory $TauriDir -Wait -NoNewWindow -PassThru
    if ($npmProc.ExitCode -eq 0) { Log "    [OK] Dependencias de Tauri instaladas." "Green" } 
    else { Log "    [X] Error al ejecutar npm install. Revisa si Node.js está en el PATH." "Red" }
} else {
    Log "    [!] No se encontró la carpeta nexus-tactical." "Red"
}

Log "`n======================================================" "Cyan"
Log "Proceso de reparación finalizado. Intenta ARRANCAR de nuevo en el panel." "Green"

$capture | Set-Clipboard