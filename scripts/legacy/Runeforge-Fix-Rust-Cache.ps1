$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$AppPath = "C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2\src-tauri"

Log "=== REPARANDO COMPILACIÓN DE DICTATE STUDIO V2 ==="
Log "El error 'can't find crate' se debe a un caché corrupto tras la purga."
Log ""

if (Test-Path $AppPath) {
    Push-Location $AppPath
    
    Log "[1/3] Limpiando artefactos de compilación de esta app..."
    & cargo clean 2>&1 | Out-Null
    
    Log "[2/3] Forzando descarga/actualización de dependencias..."
    & cargo fetch 2>&1 | Out-Null
    
    Log "[3/3] Recompilando (esto tomará unos minutos)..."
    $t = Get-Date
    $cargoOut = & cargo build --release 2>&1
    $exit = $LASTEXITCODE
    $elapsed = (Get-Date) - $t
    
    Pop-Location
    
    Log ""
    if ($exit -eq 0) {
        Log ("[OK] Compilación exitosa en {0:N1} segundos." -f $elapsed.TotalSeconds)
        $exePath = "$AppPath\target\release\dictate-studio-v2.exe"
        if (Test-Path $exePath) {
            $mb = [math]::Round((Get-Item $exePath).Length / 1MB, 2)
            Log "[OK] Ejecutable restaurado: dictate-studio-v2.exe ($mb MB)"
        }
    } else {
        Log "[X] Falló nuevamente (exit=$exit). Últimos 15 errores:"
        $cargoOut | Select-Object -Last 15 | ForEach-Object { Log "  $_" }
    }
} else {
    Log "[X] No se encontró la ruta: $AppPath"
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
