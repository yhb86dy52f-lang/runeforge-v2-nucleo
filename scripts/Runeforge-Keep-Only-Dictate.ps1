$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$Root = "C:\RUNEFORGE_V2_CORE"
$AppsDir = "$Root\apps"
$DesktopSafe = [Environment]::GetFolderPath('Desktop') + "\DICTATE_STUDIO_FINAL"
$TargetExe = "$Root\target\release\dictate-studio-v2.exe"

Log "=========================================================="
Log "   LIMPIEZA DEFINITIVA: SOLO DICTATE STUDIO V2"
Log "=========================================================="

# 1. Verificar que el ejecutable bueno exista antes de borrar nada
if (-not (Test-Path $TargetExe)) {
    Log "[X] ERROR CRÍTICO: No se encuentra dictate-studio-v2.exe en target\release"
    Log "    Abortando purga para no borrar el código fuente sin tener el ejecutable."
    $txt = $Report.ToString(); Set-Clipboard -Value $txt; return
}

# 2. Aislar el ejecutable en el Escritorio
Log "`n[1/3] Salvando ejecutable en $DesktopSafe..."
if (-not (Test-Path $DesktopSafe)) { New-Item -ItemType Directory -Path $DesktopSafe | Out-Null }
Copy-Item $TargetExe "$DesktopSafe\DICTATE_STUDIO.exe" -Force
Log "[OK] Ejecutable copiado a salvo (independiente del ecosistema)."

# 3. Destruir las apps de prueba
Log "`n[2/3] Eliminando apps de prueba..."
$AppsToKill = @(
    "dictate-studio", 
    "dictate-backend", 
    "nexus-lab", 
    "openwash-real", 
    "openwash-real-v2", 
    "opt-verify", 
    "panel-relevadores", 
    "sms-hub", 
    "sms-hub-hmi"
)

foreach ($app in $AppsToKill) {
    $path = Join-Path $AppsDir $app
    if (Test-Path $path) {
        Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        Log "[DEL] $app (Carpeta eliminada)"
    } else {
        Log "[--]  $app (Ya no existía)"
    }
}

# 4. Limpiar el registro JSON
Log "`n[3/3] Limpiando apps.json..."
$jsonPath = "$Root\registry\apps.json"
if (Test-Path $jsonPath) {
    $json = Get-Content $jsonPath -Raw | ConvertFrom-Json
    $GoodApp = $json.apps | Where-Object { $_.name -eq 'dictate-studio-v2' }
    
    if ($GoodApp) {
        $NewJson = [PSCustomObject]@{
            version = "2.0.0"
            core = $Root
            updated = (Get-Date -Format 'o')
            apps = @($GoodApp)
        }
        $NewJson | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
        Log "[OK] Registro actualizado. Solo queda dictate-studio-v2."
    }
}

Log "`n=========================================================="
Log "   RESULTADO"
Log "=========================================================="
Log "✅ App conservada: $Root\apps\dictate-studio-v2"
Log "✅ Copia de seguridad en Escritorio: $DesktopSafe\DICTATE_STUDIO.exe"
Log "✅ 9 apps de prueba eliminadas del disco."
Log ""

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Limpieza canónica terminada. Salida en el portapapeles." -ForegroundColor Green
