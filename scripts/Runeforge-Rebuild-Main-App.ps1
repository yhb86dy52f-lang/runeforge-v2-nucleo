$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$Root = "C:\RUNEFORGE_V2_CORE"
$App = "dictate-studio-v2"
$AppPath = "$Root\apps\$App\src-tauri"

Log "=========================================================="
Log "   RECOMPILANDO APP PRINCIPAL: $App"
Log "   (Esto restaurará el .exe eliminado en la purga)"
Log "=========================================================="
Log ""

if (Test-Path $AppPath) {
    Push-Location $AppPath
    Log "Iniciando cargo build --release..."
    Log "(Usando sccache, puede tardar unos minutos)"
    Log ""
    
    $t = Get-Date
    & cargo build --release 2>&1 | Tee-Object -Variable cargoOut | Out-Null
    $exit = $LASTEXITCODE
    $elapsed = (Get-Date) - $t
    
    Pop-Location
    
    if ($exit -eq 0) {
        Log ("[OK] Compilación exitosa en {0:N1} segundos." -f $elapsed.TotalSeconds)
        $exePath = "$AppPath\target\release\$App.exe"
        if (Test-Path $exePath) {
            $mb = [math]::Round((Get-Item $exePath).Length / 1MB, 2)
            Log "[OK] Ejecutable restaurado: $App.exe ($mb MB)"
        }
    } else {
        Log "[X] Falló la compilación (exit=$exit). Últimos errores:"
        $cargoOut | Select-Object -Last 10 | ForEach-Object { Log "  $_" }
    }
} else {
    Log "[X] No se encontró el directorio: $AppPath"
}

Log ""
Log "=== ESPACIO LIBRE EN DISCO ==="
$drive = Get-PSDrive C
$freeGB = [math]::Round($drive.Free / 1GB, 2)
Log "C: tiene $freeGB GB libres."

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles. Ctrl+V para pegar." -ForegroundColor Green
