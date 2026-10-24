$ErrorActionPreference = "Continue"
$cli = "C:\Program Files\Arduino CLI\arduino-cli.exe"
$url = "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"
$cache = "$env:LOCALAPPDATA\Arduino15\staging\packages"
$manifest = Import-Clixml "$env:TEMP\esp32-manifest.xml"
New-Item -ItemType Directory -Path $cache -Force | Out-Null

Write-Host "=== PASO 4 (fix): Descargar con curl + verificar hash ===" -ForegroundColor Cyan

foreach ($t in $manifest) {
    $file = Join-Path $cache (Split-Path $t.url -Leaf)
    $expected = $t.sha256.ToLower()

    if (Test-Path $file) {
        $actual = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
        if ($actual -eq $expected) {
            $mb = [math]::Round((Get-Item $file).Length / 1MB, 1)
            Write-Host "[ok] $($t.name) ($mb MB)" -ForegroundColor Green
            continue
        }
        Write-Host "[!] $($t.name) hash mismatch. Re-descargando." -ForegroundColor Yellow
        Remove-Item $file -Force
    }

    Write-Host "[get] $($t.name)@$($t.version) -> $(Split-Path $t.url -Leaf)" -ForegroundColor Yellow
    curl.exe -L --retry 20 --retry-delay 5 --retry-all-errors --connect-timeout 30 --max-time 0 --progress-bar -o "$file" "$($t.url)"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[X] curl fallo para $($t.name) (exit=$LASTEXITCODE)" -ForegroundColor Red
        exit 1
    }

    $newHash = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
    if ($newHash -ne $expected) {
        Write-Host "[X] hash incorrecto tras descarga: $newHash != $expected" -ForegroundColor Red
        Remove-Item $file -Force
        exit 1
    }
    Write-Host "[ok] $($t.name) verificado" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== PASO 5: Extraer y marcar ===" -ForegroundColor Cyan
foreach ($t in $manifest) {
    $file = Join-Path $cache (Split-Path $t.url -Leaf)
    if (-not (Test-Path $file)) { Write-Host "[X] Falta $file" -ForegroundColor Red; continue }
    if (Test-Path $t.folder) { Remove-Item $t.folder -Recurse -Force -EA SilentlyContinue }
    New-Item -ItemType Directory -Path $t.folder -Force | Out-Null

    if ($file -match '\.zip$') {
        Expand-Archive -Path $file -DestinationPath $t.folder -Force
    } elseif ($file -match '\.tar\.gz$') {
        tar.exe -xzf $file -C $t.folder
    } elseif ($file -match '\.tar\.bz2$') {
        if (Get-Command 7z.exe -EA SilentlyContinue) { 7z.exe x $file "-o$($t.folder)" -y | Out-Null }
        else { Write-Host "[!] .tar.bz2 sin 7-Zip: $($t.name)" -ForegroundColor Yellow; continue }
    }

    $subs = Get-ChildItem $t.folder -Directory
    if ($subs.Count -eq 1 -and -not (Test-Path (Join-Path $subs[0].FullName 'bin'))) {
        Get-ChildItem $subs[0].FullName | Move-Item -Destination $t.folder -Force
        Remove-Item $subs[0].FullName -Recurse -Force -EA SilentlyContinue
    }

    Set-Content -Path "$($t.folder)\$($t.name)-$($t.version).installed" -Value "" -Encoding ASCII
    Write-Host "[ok] $($t.name) extraido" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== PASO 6: Instalar core esp32:esp32@3.3.12 ===" -ForegroundColor Cyan
& $cli core install esp32:esp32@3.3.12 --additional-urls $url

Write-Host ""
Write-Host "=== PASO 7: Verificar esptool ===" -ForegroundColor Cyan
Get-ChildItem "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esptool_py" -Recurse -Filter "esptool.exe" -EA SilentlyContinue |
    Select-Object FullName, Length

Write-Host ""
Write-Host "=== FIN ===" -ForegroundColor Green
