$ErrorActionPreference = "Continue"
$cli = "C:\Program Files\Arduino CLI\arduino-cli.exe"
$url = "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"
$cache = "$env:LOCALAPPDATA\Arduino15\staging\packages"
New-Item -ItemType Directory -Path $cache -Force | Out-Null

Write-Host "=== PASO 1: Configurar indice Espressif ===" -ForegroundColor Cyan
& $cli config set board_manager.additional_urls $url
& $cli core update-index --additional-urls $url

Write-Host ""
Write-Host "=== PASO 2: Ubicar indice correcto ===" -ForegroundColor Cyan
$idxFile = Get-ChildItem "$env:LOCALAPPDATA\Arduino15" -Filter "*index*.json" -Recurse -EA SilentlyContinue |
    Where-Object { (Get-Content $_.FullName -Raw -EA SilentlyContinue) -match 'esp-rv32' } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $idxFile) {
    Write-Host "[X] No se encontro indice con esp-rv32. Revisar config." -ForegroundColor Red
    & $cli config dump
    exit 1
}
Write-Host "[OK] Indice: $($idxFile.FullName) ($([math]::Round($idxFile.Length/1KB,1)) KB)"

$json = Get-Content $idxFile.FullName -Raw | ConvertFrom-Json
$pkg  = $json.packages | Where-Object { $_.name -eq "esp32" }
Write-Host "Tools totales: $($pkg.tools.Count) | Plataformas: $($pkg.platforms.Count)"

$plat = $pkg.platforms | Where-Object { $_.version -eq '3.3.12' } | Select-Object -First 1
if (-not $plat) {
    Write-Host "[X] No hay plataforma 3.3.12. Versiones disponibles:" -ForegroundColor Red
    $pkg.platforms | Select-Object version | Sort-Object version -Unique | Format-Table
    exit 1
}
Write-Host "[OK] Plataforma 3.3.12. Dependencias: $($plat.toolsDependencies.Count)"

Write-Host ""
Write-Host "=== PASO 3: Armar manifest ===" -ForegroundColor Cyan
$manifest = @()
foreach ($dep in $plat.toolsDependencies) {
    $tool = $pkg.tools | Where-Object { $_.name -eq $dep.name -and $_.version -eq $dep.version }
    if (-not $tool) { Write-Host "[!] Sin tool: $($dep.name)@$($dep.version)" -ForegroundColor Yellow; continue }
    $sys = $tool.systems | Where-Object { $_.host -eq 'x86_64-mingw32' } | Select-Object -First 1
    if (-not $sys) { $sys = $tool.systems | Where-Object { $_.host -eq 'i686-mingw32' } | Select-Object -First 1 }
    if (-not $sys) { $sys = $tool.systems | Where-Object { $_.host -match 'mingw32|windows' } | Select-Object -First 1 }
    if (-not $sys) { Write-Host "[!] Sin host Windows: $($dep.name)" -ForegroundColor Yellow; continue }
    $manifest += [pscustomobject]@{
        name    = $dep.name
        version = $dep.version
        url     = $sys.url
        sha256  = ($sys.checksum -replace '^SHA-256:','')
        folder  = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\$($dep.name)\$($dep.version)"
    }
}
$manifest | Format-Table name, version -AutoSize
$manifest | Export-Clixml "$env:TEMP\esp32-manifest.xml"
Write-Host "[OK] Manifest: $($manifest.Count) tools guardados" -ForegroundColor Green

Write-Host ""
Write-Host "=== PASO 4: Descargar con curl ===" -ForegroundColor Cyan
foreach ($t in $manifest) {
    $file = Join-Path $cache (Split-Path $t.url -Leaf)
    if (Test-Path $file) {
        $szMB = [math]::Round((Get-Item $file).Length / 1MB, 1)
        Write-Host "[skip] $($t.name) ya esta ($szMB MB)" -ForegroundColor DarkGray
        continue
    }
    Write-Host "[get] $($t.name)@$($t.version) -> $(Split-Path $t.url -Leaf)" -ForegroundColor Yellow
    curl.exe -L -C - --retry 20 --retry-delay 5 --retry-all-errors --connect-timeout 30 --max-time 0 -o "$file" "$t.url"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[X] Fallo $($t.name). Ejecuta el script otra vez (curl reanuda)" -ForegroundColor Red
        exit 1
    }
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
    Write-Host "[OK] $($t.name) -> $($t.folder)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== PASO 6: Instalar core esp32 ===" -ForegroundColor Cyan
& $cli core install esp32:esp32@3.3.12 --additional-urls $url

Write-Host ""
Write-Host "=== PASO 7: Verificar ===" -ForegroundColor Cyan
& $cli core list
Write-Host ""
Get-ChildItem "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esptool_py" -Recurse -Filter "esptool.exe" -EA SilentlyContinue |
    Select-Object FullName, Length

Write-Host ""
Write-Host "=== FIN ===" -ForegroundColor Green
