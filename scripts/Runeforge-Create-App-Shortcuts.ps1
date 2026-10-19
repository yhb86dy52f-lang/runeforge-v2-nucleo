$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$Root = "C:\RUNEFORGE_V2_CORE"
$DesktopFolder = [Environment]::GetFolderPath('Desktop') + "\RUNEFORGE Apps"

Log "=== BUSCANDO APLICACIONES COMPILADAS ==="
if (-not (Test-Path $DesktopFolder)) { New-Item -ItemType Directory -Path $DesktopFolder | Out-Null }

# Buscar ejecutables ignorando la basura de Rust
$validExes = @()
$searchPaths = @("$Root\target\release", "$Root\apps")

foreach ($base in $searchPaths) {
    if (Test-Path $base) {
        $found = Get-ChildItem $base -Recurse -Filter "*.exe" -File -ErrorAction SilentlyContinue | 
            Where-Object { 
                $_.Name -notmatch 'build-script|build_script|_lib' -and 
                $_.FullName -notmatch '\\deps\\' 
            }
        $validExes += $found
    }
}

# Eliminar duplicados por nombre (quedarse con el más reciente)
$uniqueApps = $validExes | Group-Object Name | ForEach-Object {
    $_.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

if ($uniqueApps) {
    $shell = New-Object -ComObject WScript.Shell
    foreach ($app in $uniqueApps) {
        $shortcutPath = Join-Path $DesktopFolder "$($app.BaseName).lnk"
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $app.FullName
        $shortcut.WorkingDirectory = $app.DirectoryName
        $shortcut.Save()
        
        $mb = [math]::Round($app.Length / 1MB, 2)
        Log ("[OK] Acceso directo creado: {0} ({1} MB)" -f $app.Name, $mb)
    }
    Log "`n[INFO] Todos los accesos directos están en tu Escritorio dentro de la carpeta 'RUNEFORGE Apps'."
} else {
    Log "[X] No se encontró ningún ejecutable válido."
}

# Verificar cuáles apps del mapa JSON no tienen ejecutable
Log "`n=== APPS PENDIENTES DE RECOMPILAR (Borradas en la purga) ==="
$jsonPath = "$Root\registry\apps.json"
if (Test-Path $jsonPath) {
    $json = Get-Content $jsonPath -Raw | ConvertFrom-Json
    foreach ($app in $json.apps) {
        $exeName = "$($app.name).exe"
        $exeNameAlt = "$($app.name.Replace('-', '_')).exe"
        
        $found = $uniqueApps | Where-Object { $_.Name -eq $exeName -or $_.Name -eq $exeNameAlt }
        
        if (-not $found) {
            Log "[!] FALTA: $($app.name). (Necesita recompilarse con cargo)."
        }
    }
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
