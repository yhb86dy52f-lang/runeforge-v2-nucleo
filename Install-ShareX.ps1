# Install-ShareX.ps1 - RUNEFORGE v2.8.1 - Local-first, verificable, sin bloat
# Descarga ShareX oficial desde GitHub o winget
# Uso: .\Install-ShareX.ps1 -Mode winget|installer|portable -Verbose

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
Write-Host "[$ts] === RUNEFORGE ShareX Installer v1.0 ===" -ForegroundColor Cyan

# 1. Verificación Cajal - entorno real
if(!(Test-Path $Destination)){
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Write-Host "[$ts] Creado destino: $Destination" -ForegroundColor Yellow
}

# Detectar si ya está instalado
$installed = Get-Command ShareX -ErrorAction SilentlyContinue
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$sharexReg = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*ShareX*" } | Select-Object -First 1

if($sharexReg -and -not $Force){
    Write-Host "[$ts] ShareX ya instalado: $($sharexReg.DisplayName) v$($sharexReg.DisplayVersion) en $($sharexReg.InstallLocation)" -ForegroundColor Green
    Write-Host "[$ts] Usa -Force para reinstalar" -ForegroundColor Yellow
    exit 0
}

# 2. Auto-detectar modo
if($Mode -eq "auto"){
    if(Get-Command winget -ErrorAction SilentlyContinue){
        $Mode = "winget"
    } else {
        $Mode = "installer"
    }
    Write-Host "[$ts] Modo auto -> $Mode" -ForegroundColor Gray
}

# 3. Instalación por modo
switch($Mode){
    "winget" {
        Write-Host "[$ts] Instalando vía winget (oficial, ~100MB con .NET runtime)" -ForegroundColor Yellow
        if(!(Get-Command winget -ErrorAction SilentlyContinue)){
            Write-Host "[$ts] winget no encontrado, cambiando a installer" -ForegroundColor Red
            $Mode = "installer"
        } else {
            winget install --id ShareX.ShareX -e --accept-package-agreements --accept-source-agreements
            if($LASTEXITCODE -eq 0){
                Write-Host "[$ts] ShareX instalado vía winget OK" -ForegroundColor Green
                exit 0
            } else {
                Write-Host "[$ts] winget falló con código $LASTEXITCODE, intentando installer" -ForegroundColor Red
                $Mode = "installer"
            }
        }
    }
}

if($Mode -eq "installer"){
    Write-Host "[$ts] Descargando ShareX installer oficial desde GitHub" -ForegroundColor Yellow
    # API GitHub para obtener último release
    try {
        $apiUrl = "https://api.github.com/repos/ShareX/ShareX/releases/latest"
        Write-Host "[$ts] Consultando $apiUrl" -ForegroundColor Gray
        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "RUNEFORGE" } -UseBasicParsing
        $version = $release.tag_name
        Write-Host "[$ts] Última versión: $version" -ForegroundColor Cyan

        # Buscar asset ShareX-*.exe installer
        $asset = $release.assets | Where-Object { $_.name -like "ShareX-*-setup.exe" -or $_.name -like "ShareX-*.exe" } | Select-Object -First 1
        if(-not $asset){
            # Fallback: buscar cualquier .exe
            $asset = $release.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1
        }
        if(-not $asset){
            throw "No se encontró asset .exe en release $version"
        }
        $url = $asset.browser_download_url
        $fileName = $asset.name
        $outFile = Join-Path $Destination $fileName

        Write-Host "[$ts] Descargando $fileName" -ForegroundColor Yellow
        Write-Host "[$ts] URL: $url" -ForegroundColor Gray
        Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing -Headers @{ "User-Agent" = "RUNEFORGE" }

        $sizeMB = [math]::Round((Get-Item $outFile).Length / 1MB,2)
        Write-Host "[$ts] Descargado: $outFile ($sizeMB MB)" -ForegroundColor Green

        if(-not $NoInstall){
            Write-Host "[$ts] Instalando silenciosamente..." -ForegroundColor Yellow
            Start-Process -FilePath $outFile -ArgumentList "/VERYSILENT /NORESTART" -Wait
            Write-Host "[$ts] ShareX $version instalado OK" -ForegroundColor Green
        } else {
            Write-Host "[$ts] -NoInstall activado, solo descargado" -ForegroundColor Yellow
        }

    } catch {
        Write-Host "[$ts] ERROR: $_" -ForegroundColor Red
        Write-Host "[$ts] Fallback manual: https://github.com/ShareX/ShareX/releases/latest" -ForegroundColor Yellow
        exit 1
    }
}

if($Mode -eq "portable"){
    Write-Host "[$ts] Descargando ShareX portable" -ForegroundColor Yellow
    try {
        $apiUrl = "https://api.github.com/repos/ShareX/ShareX/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "RUNEFORGE" } -UseBasicParsing
        $asset = $release.assets | Where-Object { $_.name -like "*portable*" } | Select-Object -First 1
        if(-not $asset){
            $asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
        }
        $url = $asset.browser_download_url
        $outFile = Join-Path $Destination $asset.name
        Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
        Write-Host "[$ts] Portable descargado: $outFile" -ForegroundColor Green
        $extractPath = Join-Path $Destination "ShareX-Portable"
        Expand-Archive -Path $outFile -DestinationPath $extractPath -Force
        Write-Host "[$ts] Extraído en: $extractPath" -ForegroundColor Green
        Write-Host "[$ts] Ejecuta: $extractPath\ShareX.exe" -ForegroundColor Cyan
    } catch {
        Write-Host "[$ts] ERROR portable: $_" -ForegroundColor Red
    }
}

Write-Host "[$ts] === FIN ===" -ForegroundColor Cyan
Write-Host "[$ts] Verifica: ShareX.exe | winget list ShareX" -ForegroundColor Gray
