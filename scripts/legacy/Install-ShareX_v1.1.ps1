# Install-ShareX v1.1 - FIX detección y error 1 - RUNEFORGE
[CmdletBinding()]
param(
    [ValidateSet("winget","installer","portable","auto")]
    [string]$Mode = "auto",
    [string]$Destination = "$env:USERPROFILE\Downloads",
    [switch]$NoInstall,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[$ts] === RUNEFORGE ShareX Installer v1.1 FIX ===" -ForegroundColor Cyan

if(!(Test-Path $Destination)){ New-Item -ItemType Directory -Force -Path $Destination | Out-Null }

# FIX 1: Detección precisa - no confundir Recorder Devices for ShareX con ShareX real
$regPaths = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$realShareX = Get-ItemProperty -Path $regPaths -ErrorAction SilentlyContinue | Where-Object { 
    $_.DisplayName -eq "ShareX" -or ($_.Publisher -like "*ShareX Team*" -and $_.DisplayName -like "ShareX*")
} | Select-Object -First 1

$fakeRecorder = Get-ItemProperty -Path $regPaths -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Recorder Devices for ShareX*" } | Select-Object -First 1

if($fakeRecorder){
    Write-Host "[$ts] Detectado paquete falso que bloquea: $($fakeRecorder.DisplayName) v$($fakeRecorder.DisplayVersion)" -ForegroundColor Yellow
    Write-Host "[$ts] Esto NO es ShareX real. Se ignora para instalación." -ForegroundColor Gray
}

if($realShareX -and -not $Force){
    Write-Host "[$ts] ShareX REAL ya instalado: $($realShareX.DisplayName) v$($realShareX.DisplayVersion)" -ForegroundColor Green
    Write-Host "[$ts] Usa -Force para reinstalar" -ForegroundColor Yellow
    if($Mode -ne "portable"){ exit 0 }
} else {
    if($Force){ Write-Host "[$ts] -Force activo, ignorando detección" -ForegroundColor Yellow }
}

# FIX 2: Cerrar procesos que causan exit code 1
Write-Host "[$ts] Cerrando procesos ShareX previos que causan error 1..." -ForegroundColor Gray
Get-Process -Name "ShareX" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 1

if($Mode -eq "auto"){
    if(Get-Command winget -ErrorAction SilentlyContinue){ $Mode = "winget" } else { $Mode = "installer" }
}

if($Mode -eq "winget"){
    Write-Host "[$ts] Intentando winget con --force y log" -ForegroundColor Yellow
    # Desinstalar el falso si existe para evitar conflicto
    if($fakeRecorder -and $Force){
        Write-Host "[$ts] Desinstalando Recorder Devices for ShareX..." -ForegroundColor Yellow
        winget uninstall --id "Recorder Devices for ShareX" -e --silent --accept-source-agreements -ErrorAction SilentlyContinue
    }
    # Instalar con override para evitar error 1
    winget install --id ShareX.ShareX -e --accept-package-agreements --accept-source-agreements --force --override "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES" --disable-interactivity
    if($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189){ # -1978335189 = ya instalado
        Write-Host "[$ts] ShareX winget OK (código $LASTEXITCODE)" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "[$ts] winget falló $LASTEXITCODE - Lee log: C:\Users\$env:USERNAME\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir\ShareX*" -ForegroundColor Red
        Write-Host "[$ts] Pasando a installer directo..." -ForegroundColor Yellow
        $Mode = "installer"
    }
}

if($Mode -eq "installer" -or $Mode -eq "portable"){
    try {
        $apiUrl = "https://api.github.com/repos/ShareX/ShareX/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "RUNEFORGE" }
        $version = $release.tag_name
        Write-Host "[$ts] Última versión: $version" -ForegroundColor Cyan

        if($Mode -eq "installer"){
            $asset = $release.assets | Where-Object { $_.name -like "ShareX-*-setup.exe" } | Select-Object -First 1
            if(-not $asset){ $asset = $release.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1 }
            $url = $asset.browser_download_url
            $outFile = Join-Path $Destination $asset.name
            Write-Host "[$ts] Descargando $($asset.name)" -ForegroundColor Yellow
            Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
            Write-Host "[$ts] Descargado $outFile $([math]::Round((Get-Item $outFile).Length/1MB,2)) MB" -ForegroundColor Green
            if(-not $NoInstall){
                Write-Host "[$ts] Instalando con /VERYSILENT..." -ForegroundColor Yellow
                # Ejecutar como admin si es posible
                $psi = Start-Process -FilePath $outFile -ArgumentList "/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /NOCLOSEAPPLICATIONS" -Wait -PassThru
                if($psi.ExitCode -eq 0){ Write-Host "[$ts] Instalado OK" -ForegroundColor Green }
                else { Write-Host "[$ts] Installer exit $($psi.ExitCode) - intenta manual doble-click en $outFile" -ForegroundColor Red }
            }
        } else {
            $asset = $release.assets | Where-Object { $_.name -like "*portable.zip" -or $_.name -like "*Portable*" } | Select-Object -First 1
            if(-not $asset){ $asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1 }
            $outFile = Join-Path $Destination $asset.name
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $outFile -UseBasicParsing
            $extractPath = Join-Path $Destination "ShareX-Portable-$version"
            Expand-Archive -Path $outFile -DestinationPath $extractPath -Force
            Write-Host "[$ts] Portable en: $extractPath\ShareX.exe" -ForegroundColor Green
            Start-Process -FilePath "$extractPath\ShareX.exe" -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Host "[$ts] ERROR: $_" -ForegroundColor Red
    }
}
