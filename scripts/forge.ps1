#Requires -Version 5.1
# forge.ps1 v1.1 - CLI del taller RUNEFORGE (target-dir forzado)
param(
  [Parameter(Position=0)][string]$Command,
  [Parameter(Position=1)][string]$Name,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ROOT = 'C:\RUNEFORGE_V2_CORE'
$REG  = "$ROOT\registry\apps.json"
$CFG  = Get-Content "$ROOT\forge.json" -Raw | ConvertFrom-Json

function Get-Registry {
  if(Test-Path -LiteralPath $REG){ Get-Content $REG -Raw | ConvertFrom-Json }
  else { [pscustomobject]@{ version='1.0.0'; apps=@() } }
}
function Save-Registry($r){
  $r.updated = (Get-Date).ToString('o')
  $r | ConvertTo-Json -Depth 8 | Set-Content $REG -Encoding UTF8
}
function Resolve-App([string]$n){
  (Get-Registry).apps | Where-Object { $_.name -eq $n } | Select-Object -First 1
}
function Find-AppExe($targetDir, $appName){
  if(-not (Test-Path $targetDir)){ return $null }
  # 1) Nombre exacto o con guiones bajos en release/
  $cands = @(
    "$targetDir\release\$appName.exe",
    "$targetDir\release\$($appName -replace '-','_').exe"
  ) | Where-Object { Test-Path $_ }
  if($cands){ return $cands[0] }
  # 2) Cualquier .exe cuyo nombre contenga el app (sin deps/)
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' -and $_.Name -match [regex]::Escape($appName) } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  # 3) Fallback: exe mas reciente fuera de deps
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  return $null
}

switch($Command){

  'list' {
    $r = Get-Registry
    Write-Host "APPS REGISTRADAS ($($r.apps.Count))" -ForegroundColor Cyan
    $r.apps | ForEach-Object {
      $exe = if($_.exe -and (Test-Path $_.exe)){ $_.exe } else { '(sin binario)' }
      $flag = if($_.migrated){ ' [aislada]' } else { '' }
      Write-Host ("  {0,-24}{1}  {2}" -f $_.name, $flag, $exe)
    }
  }

  'audit' {
    Write-Host "=== AUDITORIA ===" -ForegroundColor Cyan
    $r = Get-Registry
    foreach($app in $r.apps){
      $ok  = @(); $bad = @()
      if($app.path       -and (Test-Path $app.path))       { $ok += 'path' }   else { $bad += 'path' }
      if($app.src_tauri  -and (Test-Path $app.src_tauri))  { $ok += 'src' }    else { $bad += 'src' }
      if($app.target_dir -and (Test-Path $app.target_dir)) { $ok += 'target' } else { $bad += 'target' }
      if($app.exe        -and (Test-Path $app.exe))        { $ok += 'exe' }    else { $bad += 'exe' }
      Write-Host ("  {0,-24} OK=[{1}]  FALTA=[{2}]" -f $app.name, ($ok -join ','), ($bad -join ','))
    }
  }

  'new' {
    if(-not $Name){ throw "Uso: forge new <nombre> [-Force]" }
    $src = "$ROOT\apps\_template"
    $dst = "$ROOT\apps\$Name"
    if(-not (Test-Path $src)){ throw "Falta el template: $src" }
    if((Test-Path $dst) -and -not $Force){ throw "Ya existe $dst (usa -Force)" }
    Copy-Item $src $dst -Recurse -Force
    Get-ChildItem $dst -Recurse -File | ForEach-Object {
      $txt = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if($txt -and $txt -match '__APPNAME__'){
        Set-Content $_.FullName -Value ($txt -replace '__APPNAME__',$Name) -Encoding UTF8 -NoNewline
      }
    }
    $r = Get-Registry
    $r.apps += [ordered]@{
      name       = $Name
      path       = $dst
      src_tauri  = "$dst\src-tauri"
      target_dir = "$dst\src-tauri\target"
      exe        = $null
      migrated   = $true
      last_build = $null
    }
    Save-Registry $r
    Write-Host "[OK] App creada: $dst" -ForegroundColor Green
  }

  'build' {
    if(-not $Name){ throw "Uso: forge build <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if(-not (Test-Path $app.src_tauri)){ throw "Falta src-tauri en $Name" }

    # target-dir ABSOLUTO, forzado por --target-dir (gana sobre env, workspace y config)
    $targetAbs = $app.target_dir
    if(-not (Test-Path $targetAbs)){ New-Item -ItemType Directory -Path $targetAbs -Force | Out-Null }

    # Neutralizar CARGO_TARGET_DIR heredado SOLO en este bloque
    $oldCTD = $env:CARGO_TARGET_DIR
    $env:CARGO_TARGET_DIR = $null

    Push-Location $app.src_tauri
    try {
      Write-Host "[forge] cargo build --release --target-dir `"$targetAbs`"" -ForegroundColor DarkGray
      & cargo build --release --target-dir $targetAbs
      if($LASTEXITCODE -ne 0){ throw "cargo build fallo con codigo $LASTEXITCODE" }
    } finally {
      Pop-Location
      if($oldCTD){ $env:CARGO_TARGET_DIR = $oldCTD }
    }

    # Localizar .exe en el target aislado
    $exe = Find-AppExe $targetAbs $Name

    if($exe){
      $r = Get-Registry
      $r.apps = $r.apps | ForEach-Object {
        if(#Requires -Version 5.1
# forge.ps1 v1.1 - CLI del taller RUNEFORGE (target-dir forzado)
param(
  [Parameter(Position=0)][string]$Command,
  [Parameter(Position=1)][string]$Name,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ROOT = 'C:\RUNEFORGE_V2_CORE'
$REG  = "$ROOT\registry\apps.json"
$CFG  = Get-Content "$ROOT\forge.json" -Raw | ConvertFrom-Json

function Get-Registry {
  if(Test-Path -LiteralPath $REG){ Get-Content $REG -Raw | ConvertFrom-Json }
  else { [pscustomobject]@{ version='1.0.0'; apps=@() } }
}
function Save-Registry($r){
  $r.updated = (Get-Date).ToString('o')
  $r | ConvertTo-Json -Depth 8 | Set-Content $REG -Encoding UTF8
}
function Resolve-App([string]$n){
  (Get-Registry).apps | Where-Object { $_.name -eq $n } | Select-Object -First 1
}
function Find-AppExe($targetDir, $appName){
  if(-not (Test-Path $targetDir)){ return $null }
  # 1) Nombre exacto o con guiones bajos en release/
  $cands = @(
    "$targetDir\release\$appName.exe",
    "$targetDir\release\$($appName -replace '-','_').exe"
  ) | Where-Object { Test-Path $_ }
  if($cands){ return $cands[0] }
  # 2) Cualquier .exe cuyo nombre contenga el app (sin deps/)
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' -and $_.Name -match [regex]::Escape($appName) } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  # 3) Fallback: exe mas reciente fuera de deps
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  return $null
}

switch($Command){

  'list' {
    $r = Get-Registry
    Write-Host "APPS REGISTRADAS ($($r.apps.Count))" -ForegroundColor Cyan
    $r.apps | ForEach-Object {
      $exe = if($_.exe -and (Test-Path $_.exe)){ $_.exe } else { '(sin binario)' }
      $flag = if($_.migrated){ ' [aislada]' } else { '' }
      Write-Host ("  {0,-24}{1}  {2}" -f $_.name, $flag, $exe)
    }
  }

  'audit' {
    Write-Host "=== AUDITORIA ===" -ForegroundColor Cyan
    $r = Get-Registry
    foreach($app in $r.apps){
      $ok  = @(); $bad = @()
      if($app.path       -and (Test-Path $app.path))       { $ok += 'path' }   else { $bad += 'path' }
      if($app.src_tauri  -and (Test-Path $app.src_tauri))  { $ok += 'src' }    else { $bad += 'src' }
      if($app.target_dir -and (Test-Path $app.target_dir)) { $ok += 'target' } else { $bad += 'target' }
      if($app.exe        -and (Test-Path $app.exe))        { $ok += 'exe' }    else { $bad += 'exe' }
      Write-Host ("  {0,-24} OK=[{1}]  FALTA=[{2}]" -f $app.name, ($ok -join ','), ($bad -join ','))
    }
  }

  'new' {
    if(-not $Name){ throw "Uso: forge new <nombre> [-Force]" }
    $src = "$ROOT\apps\_template"
    $dst = "$ROOT\apps\$Name"
    if(-not (Test-Path $src)){ throw "Falta el template: $src" }
    if((Test-Path $dst) -and -not $Force){ throw "Ya existe $dst (usa -Force)" }
    Copy-Item $src $dst -Recurse -Force
    Get-ChildItem $dst -Recurse -File | ForEach-Object {
      $txt = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if($txt -and $txt -match '__APPNAME__'){
        Set-Content $_.FullName -Value ($txt -replace '__APPNAME__',$Name) -Encoding UTF8 -NoNewline
      }
    }
    $r = Get-Registry
    $r.apps += [ordered]@{
      name       = $Name
      path       = $dst
      src_tauri  = "$dst\src-tauri"
      target_dir = "$dst\src-tauri\target"
      exe        = $null
      migrated   = $true
      last_build = $null
    }
    Save-Registry $r
    Write-Host "[OK] App creada: $dst" -ForegroundColor Green
  }

  'build' {
    if(-not $Name){ throw "Uso: forge build <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if(-not (Test-Path $app.src_tauri)){ throw "Falta src-tauri en $Name" }

    # target-dir ABSOLUTO, forzado por --target-dir (gana sobre env, workspace y config)
    $targetAbs = $app.target_dir
    if(-not (Test-Path $targetAbs)){ New-Item -ItemType Directory -Path $targetAbs -Force | Out-Null }

    # Neutralizar CARGO_TARGET_DIR heredado SOLO en este bloque
    $oldCTD = $env:CARGO_TARGET_DIR
    $env:CARGO_TARGET_DIR = $null

    Push-Location $app.src_tauri
    try {
      Write-Host "[forge] cargo build --release --target-dir `"$targetAbs`"" -ForegroundColor DarkGray
      & cargo build --release --target-dir $targetAbs
      if($LASTEXITCODE -ne 0){ throw "cargo build fallo con codigo $LASTEXITCODE" }
    } finally {
      Pop-Location
      if($oldCTD){ $env:CARGO_TARGET_DIR = $oldCTD }
    }

    # Localizar .exe en el target aislado
    $exe = Find-AppExe $targetAbs $Name

    if($exe){
      $r = Get-Registry
      $r.apps = $r.apps | ForEach-Object {
        if($_.name -eq $Name){
          $_.exe        = $exe
          $_.bin_name   = Split-Path $exe -Leaf
          $_.migrated   = $true
          $_.last_build = (Get-Date).ToString('o')
        }
        $_
      }
      Save-Registry $r
      Write-Host "[OK] Binario aislado: $exe" -ForegroundColor Green

      # Crear/actualizar acceso directo en el Escritorio real
      $lnkP = Join-Path $CFG.desktop "$Name.lnk"
      try {
        $ws  = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($lnkP)
        $lnk.TargetPath       = $exe
        $lnk.WorkingDirectory = Split-Path $exe -Parent
        $lnk.IconLocation     = "$exe,0"
        $lnk.Description      = "RUNEFORGE :: $Name"
        $lnk.Save()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
        Write-Host "[OK] Acceso directo: $lnkP" -ForegroundColor Green
      } catch { Write-Host "[WARN] No se pudo crear .lnk: $($_.Exception.Message)" }
    } else {
      Write-Host "[WARN] cargo OK pero sin .exe en $targetAbs" -ForegroundColor Yellow
      Write-Host "       Revisa si el crate solo produce lib (crate-type = [\"lib\"])." -ForegroundColor Yellow
    }
  }

  'run' {
    if(-not $Name){ throw "Uso: forge run <nombre>" }
    $app = Resolve-App $Name
    if(-not $app -or -not $app.exe -or -not (Test-Path $app.exe)){
      Write-Host "[forge] Sin binario, construyendo..." -ForegroundColor DarkGray
      & $PSCommandPath build $Name
      $app = Resolve-App $Name
    }
    if(-not $app.exe -or -not (Test-Path $app.exe)){
      throw "No hay binario para $Name"
    }
    $dir = Split-Path $app.exe -Parent
    Start-Process -FilePath $app.exe -WorkingDirectory $dir
    Write-Host "[OK] Lanzado: $($app.exe)" -ForegroundColor Green
  }

  'open' { & $PSCommandPath run $Name }

  'clean' {
    if(-not $Name){ throw "Uso: forge clean <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if($app.target_dir -and (Test-Path $app.target_dir)){
      Remove-Item $app.target_dir -Recurse -Force
      Write-Host "[OK] Limpiado: $($app.target_dir)" -ForegroundColor Green
    } else { Write-Host "[--] Nada que limpiar" }
  }

  default {
    Write-Host @"
FORGE CLI v1.1 - RUNEFORGE
Uso: forge <comando> [nombre] [-Force]

  list / audit
  new   <nombre>
  build <nombre>     (target-dir aislado, forzado)
  run   <nombre>
  clean <nombre>
"@
  }
}.name -eq $Name){
          #Requires -Version 5.1
# forge.ps1 v1.1 - CLI del taller RUNEFORGE (target-dir forzado)
param(
  [Parameter(Position=0)][string]$Command,
  [Parameter(Position=1)][string]$Name,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ROOT = 'C:\RUNEFORGE_V2_CORE'
$REG  = "$ROOT\registry\apps.json"
$CFG  = Get-Content "$ROOT\forge.json" -Raw | ConvertFrom-Json

function Get-Registry {
  if(Test-Path -LiteralPath $REG){ Get-Content $REG -Raw | ConvertFrom-Json }
  else { [pscustomobject]@{ version='1.0.0'; apps=@() } }
}
function Save-Registry($r){
  $r.updated = (Get-Date).ToString('o')
  $r | ConvertTo-Json -Depth 8 | Set-Content $REG -Encoding UTF8
}
function Resolve-App([string]$n){
  (Get-Registry).apps | Where-Object { $_.name -eq $n } | Select-Object -First 1
}
function Find-AppExe($targetDir, $appName){
  if(-not (Test-Path $targetDir)){ return $null }
  # 1) Nombre exacto o con guiones bajos en release/
  $cands = @(
    "$targetDir\release\$appName.exe",
    "$targetDir\release\$($appName -replace '-','_').exe"
  ) | Where-Object { Test-Path $_ }
  if($cands){ return $cands[0] }
  # 2) Cualquier .exe cuyo nombre contenga el app (sin deps/)
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' -and $_.Name -match [regex]::Escape($appName) } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  # 3) Fallback: exe mas reciente fuera de deps
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  return $null
}

switch($Command){

  'list' {
    $r = Get-Registry
    Write-Host "APPS REGISTRADAS ($($r.apps.Count))" -ForegroundColor Cyan
    $r.apps | ForEach-Object {
      $exe = if($_.exe -and (Test-Path $_.exe)){ $_.exe } else { '(sin binario)' }
      $flag = if($_.migrated){ ' [aislada]' } else { '' }
      Write-Host ("  {0,-24}{1}  {2}" -f $_.name, $flag, $exe)
    }
  }

  'audit' {
    Write-Host "=== AUDITORIA ===" -ForegroundColor Cyan
    $r = Get-Registry
    foreach($app in $r.apps){
      $ok  = @(); $bad = @()
      if($app.path       -and (Test-Path $app.path))       { $ok += 'path' }   else { $bad += 'path' }
      if($app.src_tauri  -and (Test-Path $app.src_tauri))  { $ok += 'src' }    else { $bad += 'src' }
      if($app.target_dir -and (Test-Path $app.target_dir)) { $ok += 'target' } else { $bad += 'target' }
      if($app.exe        -and (Test-Path $app.exe))        { $ok += 'exe' }    else { $bad += 'exe' }
      Write-Host ("  {0,-24} OK=[{1}]  FALTA=[{2}]" -f $app.name, ($ok -join ','), ($bad -join ','))
    }
  }

  'new' {
    if(-not $Name){ throw "Uso: forge new <nombre> [-Force]" }
    $src = "$ROOT\apps\_template"
    $dst = "$ROOT\apps\$Name"
    if(-not (Test-Path $src)){ throw "Falta el template: $src" }
    if((Test-Path $dst) -and -not $Force){ throw "Ya existe $dst (usa -Force)" }
    Copy-Item $src $dst -Recurse -Force
    Get-ChildItem $dst -Recurse -File | ForEach-Object {
      $txt = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if($txt -and $txt -match '__APPNAME__'){
        Set-Content $_.FullName -Value ($txt -replace '__APPNAME__',$Name) -Encoding UTF8 -NoNewline
      }
    }
    $r = Get-Registry
    $r.apps += [ordered]@{
      name       = $Name
      path       = $dst
      src_tauri  = "$dst\src-tauri"
      target_dir = "$dst\src-tauri\target"
      exe        = $null
      migrated   = $true
      last_build = $null
    }
    Save-Registry $r
    Write-Host "[OK] App creada: $dst" -ForegroundColor Green
  }

  'build' {
    if(-not $Name){ throw "Uso: forge build <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if(-not (Test-Path $app.src_tauri)){ throw "Falta src-tauri en $Name" }

    # target-dir ABSOLUTO, forzado por --target-dir (gana sobre env, workspace y config)
    $targetAbs = $app.target_dir
    if(-not (Test-Path $targetAbs)){ New-Item -ItemType Directory -Path $targetAbs -Force | Out-Null }

    # Neutralizar CARGO_TARGET_DIR heredado SOLO en este bloque
    $oldCTD = $env:CARGO_TARGET_DIR
    $env:CARGO_TARGET_DIR = $null

    Push-Location $app.src_tauri
    try {
      Write-Host "[forge] cargo build --release --target-dir `"$targetAbs`"" -ForegroundColor DarkGray
      & cargo build --release --target-dir $targetAbs
      if($LASTEXITCODE -ne 0){ throw "cargo build fallo con codigo $LASTEXITCODE" }
    } finally {
      Pop-Location
      if($oldCTD){ $env:CARGO_TARGET_DIR = $oldCTD }
    }

    # Localizar .exe en el target aislado
    $exe = Find-AppExe $targetAbs $Name

    if($exe){
      $r = Get-Registry
      $r.apps = $r.apps | ForEach-Object {
        if($_.name -eq $Name){
          $_.exe        = $exe
          $_.bin_name   = Split-Path $exe -Leaf
          $_.migrated   = $true
          $_.last_build = (Get-Date).ToString('o')
        }
        $_
      }
      Save-Registry $r
      Write-Host "[OK] Binario aislado: $exe" -ForegroundColor Green

      # Crear/actualizar acceso directo en el Escritorio real
      $lnkP = Join-Path $CFG.desktop "$Name.lnk"
      try {
        $ws  = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($lnkP)
        $lnk.TargetPath       = $exe
        $lnk.WorkingDirectory = Split-Path $exe -Parent
        $lnk.IconLocation     = "$exe,0"
        $lnk.Description      = "RUNEFORGE :: $Name"
        $lnk.Save()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
        Write-Host "[OK] Acceso directo: $lnkP" -ForegroundColor Green
      } catch { Write-Host "[WARN] No se pudo crear .lnk: $($_.Exception.Message)" }
    } else {
      Write-Host "[WARN] cargo OK pero sin .exe en $targetAbs" -ForegroundColor Yellow
      Write-Host "       Revisa si el crate solo produce lib (crate-type = [\"lib\"])." -ForegroundColor Yellow
    }
  }

  'run' {
    if(-not $Name){ throw "Uso: forge run <nombre>" }
    $app = Resolve-App $Name
    if(-not $app -or -not $app.exe -or -not (Test-Path $app.exe)){
      Write-Host "[forge] Sin binario, construyendo..." -ForegroundColor DarkGray
      & $PSCommandPath build $Name
      $app = Resolve-App $Name
    }
    if(-not $app.exe -or -not (Test-Path $app.exe)){
      throw "No hay binario para $Name"
    }
    $dir = Split-Path $app.exe -Parent
    Start-Process -FilePath $app.exe -WorkingDirectory $dir
    Write-Host "[OK] Lanzado: $($app.exe)" -ForegroundColor Green
  }

  'open' { & $PSCommandPath run $Name }

  'clean' {
    if(-not $Name){ throw "Uso: forge clean <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if($app.target_dir -and (Test-Path $app.target_dir)){
      Remove-Item $app.target_dir -Recurse -Force
      Write-Host "[OK] Limpiado: $($app.target_dir)" -ForegroundColor Green
    } else { Write-Host "[--] Nada que limpiar" }
  }

  default {
    Write-Host @"
FORGE CLI v1.1 - RUNEFORGE
Uso: forge <comando> [nombre] [-Force]

  list / audit
  new   <nombre>
  build <nombre>     (target-dir aislado, forzado)
  run   <nombre>
  clean <nombre>
"@
  }
} | Add-Member -NotePropertyName 'exe'        -NotePropertyValue $exe                     -Force
          #Requires -Version 5.1
# forge.ps1 v1.1 - CLI del taller RUNEFORGE (target-dir forzado)
param(
  [Parameter(Position=0)][string]$Command,
  [Parameter(Position=1)][string]$Name,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ROOT = 'C:\RUNEFORGE_V2_CORE'
$REG  = "$ROOT\registry\apps.json"
$CFG  = Get-Content "$ROOT\forge.json" -Raw | ConvertFrom-Json

function Get-Registry {
  if(Test-Path -LiteralPath $REG){ Get-Content $REG -Raw | ConvertFrom-Json }
  else { [pscustomobject]@{ version='1.0.0'; apps=@() } }
}
function Save-Registry($r){
  $r.updated = (Get-Date).ToString('o')
  $r | ConvertTo-Json -Depth 8 | Set-Content $REG -Encoding UTF8
}
function Resolve-App([string]$n){
  (Get-Registry).apps | Where-Object { $_.name -eq $n } | Select-Object -First 1
}
function Find-AppExe($targetDir, $appName){
  if(-not (Test-Path $targetDir)){ return $null }
  # 1) Nombre exacto o con guiones bajos en release/
  $cands = @(
    "$targetDir\release\$appName.exe",
    "$targetDir\release\$($appName -replace '-','_').exe"
  ) | Where-Object { Test-Path $_ }
  if($cands){ return $cands[0] }
  # 2) Cualquier .exe cuyo nombre contenga el app (sin deps/)
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' -and $_.Name -match [regex]::Escape($appName) } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  # 3) Fallback: exe mas reciente fuera de deps
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  return $null
}

switch($Command){

  'list' {
    $r = Get-Registry
    Write-Host "APPS REGISTRADAS ($($r.apps.Count))" -ForegroundColor Cyan
    $r.apps | ForEach-Object {
      $exe = if($_.exe -and (Test-Path $_.exe)){ $_.exe } else { '(sin binario)' }
      $flag = if($_.migrated){ ' [aislada]' } else { '' }
      Write-Host ("  {0,-24}{1}  {2}" -f $_.name, $flag, $exe)
    }
  }

  'audit' {
    Write-Host "=== AUDITORIA ===" -ForegroundColor Cyan
    $r = Get-Registry
    foreach($app in $r.apps){
      $ok  = @(); $bad = @()
      if($app.path       -and (Test-Path $app.path))       { $ok += 'path' }   else { $bad += 'path' }
      if($app.src_tauri  -and (Test-Path $app.src_tauri))  { $ok += 'src' }    else { $bad += 'src' }
      if($app.target_dir -and (Test-Path $app.target_dir)) { $ok += 'target' } else { $bad += 'target' }
      if($app.exe        -and (Test-Path $app.exe))        { $ok += 'exe' }    else { $bad += 'exe' }
      Write-Host ("  {0,-24} OK=[{1}]  FALTA=[{2}]" -f $app.name, ($ok -join ','), ($bad -join ','))
    }
  }

  'new' {
    if(-not $Name){ throw "Uso: forge new <nombre> [-Force]" }
    $src = "$ROOT\apps\_template"
    $dst = "$ROOT\apps\$Name"
    if(-not (Test-Path $src)){ throw "Falta el template: $src" }
    if((Test-Path $dst) -and -not $Force){ throw "Ya existe $dst (usa -Force)" }
    Copy-Item $src $dst -Recurse -Force
    Get-ChildItem $dst -Recurse -File | ForEach-Object {
      $txt = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if($txt -and $txt -match '__APPNAME__'){
        Set-Content $_.FullName -Value ($txt -replace '__APPNAME__',$Name) -Encoding UTF8 -NoNewline
      }
    }
    $r = Get-Registry
    $r.apps += [ordered]@{
      name       = $Name
      path       = $dst
      src_tauri  = "$dst\src-tauri"
      target_dir = "$dst\src-tauri\target"
      exe        = $null
      migrated   = $true
      last_build = $null
    }
    Save-Registry $r
    Write-Host "[OK] App creada: $dst" -ForegroundColor Green
  }

  'build' {
    if(-not $Name){ throw "Uso: forge build <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if(-not (Test-Path $app.src_tauri)){ throw "Falta src-tauri en $Name" }

    # target-dir ABSOLUTO, forzado por --target-dir (gana sobre env, workspace y config)
    $targetAbs = $app.target_dir
    if(-not (Test-Path $targetAbs)){ New-Item -ItemType Directory -Path $targetAbs -Force | Out-Null }

    # Neutralizar CARGO_TARGET_DIR heredado SOLO en este bloque
    $oldCTD = $env:CARGO_TARGET_DIR
    $env:CARGO_TARGET_DIR = $null

    Push-Location $app.src_tauri
    try {
      Write-Host "[forge] cargo build --release --target-dir `"$targetAbs`"" -ForegroundColor DarkGray
      & cargo build --release --target-dir $targetAbs
      if($LASTEXITCODE -ne 0){ throw "cargo build fallo con codigo $LASTEXITCODE" }
    } finally {
      Pop-Location
      if($oldCTD){ $env:CARGO_TARGET_DIR = $oldCTD }
    }

    # Localizar .exe en el target aislado
    $exe = Find-AppExe $targetAbs $Name

    if($exe){
      $r = Get-Registry
      $r.apps = $r.apps | ForEach-Object {
        if($_.name -eq $Name){
          $_.exe        = $exe
          $_.bin_name   = Split-Path $exe -Leaf
          $_.migrated   = $true
          $_.last_build = (Get-Date).ToString('o')
        }
        $_
      }
      Save-Registry $r
      Write-Host "[OK] Binario aislado: $exe" -ForegroundColor Green

      # Crear/actualizar acceso directo en el Escritorio real
      $lnkP = Join-Path $CFG.desktop "$Name.lnk"
      try {
        $ws  = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($lnkP)
        $lnk.TargetPath       = $exe
        $lnk.WorkingDirectory = Split-Path $exe -Parent
        $lnk.IconLocation     = "$exe,0"
        $lnk.Description      = "RUNEFORGE :: $Name"
        $lnk.Save()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
        Write-Host "[OK] Acceso directo: $lnkP" -ForegroundColor Green
      } catch { Write-Host "[WARN] No se pudo crear .lnk: $($_.Exception.Message)" }
    } else {
      Write-Host "[WARN] cargo OK pero sin .exe en $targetAbs" -ForegroundColor Yellow
      Write-Host "       Revisa si el crate solo produce lib (crate-type = [\"lib\"])." -ForegroundColor Yellow
    }
  }

  'run' {
    if(-not $Name){ throw "Uso: forge run <nombre>" }
    $app = Resolve-App $Name
    if(-not $app -or -not $app.exe -or -not (Test-Path $app.exe)){
      Write-Host "[forge] Sin binario, construyendo..." -ForegroundColor DarkGray
      & $PSCommandPath build $Name
      $app = Resolve-App $Name
    }
    if(-not $app.exe -or -not (Test-Path $app.exe)){
      throw "No hay binario para $Name"
    }
    $dir = Split-Path $app.exe -Parent
    Start-Process -FilePath $app.exe -WorkingDirectory $dir
    Write-Host "[OK] Lanzado: $($app.exe)" -ForegroundColor Green
  }

  'open' { & $PSCommandPath run $Name }

  'clean' {
    if(-not $Name){ throw "Uso: forge clean <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if($app.target_dir -and (Test-Path $app.target_dir)){
      Remove-Item $app.target_dir -Recurse -Force
      Write-Host "[OK] Limpiado: $($app.target_dir)" -ForegroundColor Green
    } else { Write-Host "[--] Nada que limpiar" }
  }

  default {
    Write-Host @"
FORGE CLI v1.1 - RUNEFORGE
Uso: forge <comando> [nombre] [-Force]

  list / audit
  new   <nombre>
  build <nombre>     (target-dir aislado, forzado)
  run   <nombre>
  clean <nombre>
"@
  }
} | Add-Member -NotePropertyName 'bin_name'   -NotePropertyValue (Split-Path $exe -Leaf)  -Force
          #Requires -Version 5.1
# forge.ps1 v1.1 - CLI del taller RUNEFORGE (target-dir forzado)
param(
  [Parameter(Position=0)][string]$Command,
  [Parameter(Position=1)][string]$Name,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ROOT = 'C:\RUNEFORGE_V2_CORE'
$REG  = "$ROOT\registry\apps.json"
$CFG  = Get-Content "$ROOT\forge.json" -Raw | ConvertFrom-Json

function Get-Registry {
  if(Test-Path -LiteralPath $REG){ Get-Content $REG -Raw | ConvertFrom-Json }
  else { [pscustomobject]@{ version='1.0.0'; apps=@() } }
}
function Save-Registry($r){
  $r.updated = (Get-Date).ToString('o')
  $r | ConvertTo-Json -Depth 8 | Set-Content $REG -Encoding UTF8
}
function Resolve-App([string]$n){
  (Get-Registry).apps | Where-Object { $_.name -eq $n } | Select-Object -First 1
}
function Find-AppExe($targetDir, $appName){
  if(-not (Test-Path $targetDir)){ return $null }
  # 1) Nombre exacto o con guiones bajos en release/
  $cands = @(
    "$targetDir\release\$appName.exe",
    "$targetDir\release\$($appName -replace '-','_').exe"
  ) | Where-Object { Test-Path $_ }
  if($cands){ return $cands[0] }
  # 2) Cualquier .exe cuyo nombre contenga el app (sin deps/)
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' -and $_.Name -match [regex]::Escape($appName) } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  # 3) Fallback: exe mas reciente fuera de deps
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  return $null
}

switch($Command){

  'list' {
    $r = Get-Registry
    Write-Host "APPS REGISTRADAS ($($r.apps.Count))" -ForegroundColor Cyan
    $r.apps | ForEach-Object {
      $exe = if($_.exe -and (Test-Path $_.exe)){ $_.exe } else { '(sin binario)' }
      $flag = if($_.migrated){ ' [aislada]' } else { '' }
      Write-Host ("  {0,-24}{1}  {2}" -f $_.name, $flag, $exe)
    }
  }

  'audit' {
    Write-Host "=== AUDITORIA ===" -ForegroundColor Cyan
    $r = Get-Registry
    foreach($app in $r.apps){
      $ok  = @(); $bad = @()
      if($app.path       -and (Test-Path $app.path))       { $ok += 'path' }   else { $bad += 'path' }
      if($app.src_tauri  -and (Test-Path $app.src_tauri))  { $ok += 'src' }    else { $bad += 'src' }
      if($app.target_dir -and (Test-Path $app.target_dir)) { $ok += 'target' } else { $bad += 'target' }
      if($app.exe        -and (Test-Path $app.exe))        { $ok += 'exe' }    else { $bad += 'exe' }
      Write-Host ("  {0,-24} OK=[{1}]  FALTA=[{2}]" -f $app.name, ($ok -join ','), ($bad -join ','))
    }
  }

  'new' {
    if(-not $Name){ throw "Uso: forge new <nombre> [-Force]" }
    $src = "$ROOT\apps\_template"
    $dst = "$ROOT\apps\$Name"
    if(-not (Test-Path $src)){ throw "Falta el template: $src" }
    if((Test-Path $dst) -and -not $Force){ throw "Ya existe $dst (usa -Force)" }
    Copy-Item $src $dst -Recurse -Force
    Get-ChildItem $dst -Recurse -File | ForEach-Object {
      $txt = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if($txt -and $txt -match '__APPNAME__'){
        Set-Content $_.FullName -Value ($txt -replace '__APPNAME__',$Name) -Encoding UTF8 -NoNewline
      }
    }
    $r = Get-Registry
    $r.apps += [ordered]@{
      name       = $Name
      path       = $dst
      src_tauri  = "$dst\src-tauri"
      target_dir = "$dst\src-tauri\target"
      exe        = $null
      migrated   = $true
      last_build = $null
    }
    Save-Registry $r
    Write-Host "[OK] App creada: $dst" -ForegroundColor Green
  }

  'build' {
    if(-not $Name){ throw "Uso: forge build <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if(-not (Test-Path $app.src_tauri)){ throw "Falta src-tauri en $Name" }

    # target-dir ABSOLUTO, forzado por --target-dir (gana sobre env, workspace y config)
    $targetAbs = $app.target_dir
    if(-not (Test-Path $targetAbs)){ New-Item -ItemType Directory -Path $targetAbs -Force | Out-Null }

    # Neutralizar CARGO_TARGET_DIR heredado SOLO en este bloque
    $oldCTD = $env:CARGO_TARGET_DIR
    $env:CARGO_TARGET_DIR = $null

    Push-Location $app.src_tauri
    try {
      Write-Host "[forge] cargo build --release --target-dir `"$targetAbs`"" -ForegroundColor DarkGray
      & cargo build --release --target-dir $targetAbs
      if($LASTEXITCODE -ne 0){ throw "cargo build fallo con codigo $LASTEXITCODE" }
    } finally {
      Pop-Location
      if($oldCTD){ $env:CARGO_TARGET_DIR = $oldCTD }
    }

    # Localizar .exe en el target aislado
    $exe = Find-AppExe $targetAbs $Name

    if($exe){
      $r = Get-Registry
      $r.apps = $r.apps | ForEach-Object {
        if($_.name -eq $Name){
          $_.exe        = $exe
          $_.bin_name   = Split-Path $exe -Leaf
          $_.migrated   = $true
          $_.last_build = (Get-Date).ToString('o')
        }
        $_
      }
      Save-Registry $r
      Write-Host "[OK] Binario aislado: $exe" -ForegroundColor Green

      # Crear/actualizar acceso directo en el Escritorio real
      $lnkP = Join-Path $CFG.desktop "$Name.lnk"
      try {
        $ws  = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($lnkP)
        $lnk.TargetPath       = $exe
        $lnk.WorkingDirectory = Split-Path $exe -Parent
        $lnk.IconLocation     = "$exe,0"
        $lnk.Description      = "RUNEFORGE :: $Name"
        $lnk.Save()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
        Write-Host "[OK] Acceso directo: $lnkP" -ForegroundColor Green
      } catch { Write-Host "[WARN] No se pudo crear .lnk: $($_.Exception.Message)" }
    } else {
      Write-Host "[WARN] cargo OK pero sin .exe en $targetAbs" -ForegroundColor Yellow
      Write-Host "       Revisa si el crate solo produce lib (crate-type = [\"lib\"])." -ForegroundColor Yellow
    }
  }

  'run' {
    if(-not $Name){ throw "Uso: forge run <nombre>" }
    $app = Resolve-App $Name
    if(-not $app -or -not $app.exe -or -not (Test-Path $app.exe)){
      Write-Host "[forge] Sin binario, construyendo..." -ForegroundColor DarkGray
      & $PSCommandPath build $Name
      $app = Resolve-App $Name
    }
    if(-not $app.exe -or -not (Test-Path $app.exe)){
      throw "No hay binario para $Name"
    }
    $dir = Split-Path $app.exe -Parent
    Start-Process -FilePath $app.exe -WorkingDirectory $dir
    Write-Host "[OK] Lanzado: $($app.exe)" -ForegroundColor Green
  }

  'open' { & $PSCommandPath run $Name }

  'clean' {
    if(-not $Name){ throw "Uso: forge clean <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if($app.target_dir -and (Test-Path $app.target_dir)){
      Remove-Item $app.target_dir -Recurse -Force
      Write-Host "[OK] Limpiado: $($app.target_dir)" -ForegroundColor Green
    } else { Write-Host "[--] Nada que limpiar" }
  }

  default {
    Write-Host @"
FORGE CLI v1.1 - RUNEFORGE
Uso: forge <comando> [nombre] [-Force]

  list / audit
  new   <nombre>
  build <nombre>     (target-dir aislado, forzado)
  run   <nombre>
  clean <nombre>
"@
  }
} | Add-Member -NotePropertyName 'migrated'   -NotePropertyValue $true                   -Force
          #Requires -Version 5.1
# forge.ps1 v1.1 - CLI del taller RUNEFORGE (target-dir forzado)
param(
  [Parameter(Position=0)][string]$Command,
  [Parameter(Position=1)][string]$Name,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ROOT = 'C:\RUNEFORGE_V2_CORE'
$REG  = "$ROOT\registry\apps.json"
$CFG  = Get-Content "$ROOT\forge.json" -Raw | ConvertFrom-Json

function Get-Registry {
  if(Test-Path -LiteralPath $REG){ Get-Content $REG -Raw | ConvertFrom-Json }
  else { [pscustomobject]@{ version='1.0.0'; apps=@() } }
}
function Save-Registry($r){
  $r.updated = (Get-Date).ToString('o')
  $r | ConvertTo-Json -Depth 8 | Set-Content $REG -Encoding UTF8
}
function Resolve-App([string]$n){
  (Get-Registry).apps | Where-Object { $_.name -eq $n } | Select-Object -First 1
}
function Find-AppExe($targetDir, $appName){
  if(-not (Test-Path $targetDir)){ return $null }
  # 1) Nombre exacto o con guiones bajos en release/
  $cands = @(
    "$targetDir\release\$appName.exe",
    "$targetDir\release\$($appName -replace '-','_').exe"
  ) | Where-Object { Test-Path $_ }
  if($cands){ return $cands[0] }
  # 2) Cualquier .exe cuyo nombre contenga el app (sin deps/)
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' -and $_.Name -match [regex]::Escape($appName) } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  # 3) Fallback: exe mas reciente fuera de deps
  $hit = Get-ChildItem $targetDir -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue |
         Where-Object { $_.FullName -notmatch '\\deps\\' } |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if($hit){ return $hit.FullName }
  return $null
}

switch($Command){

  'list' {
    $r = Get-Registry
    Write-Host "APPS REGISTRADAS ($($r.apps.Count))" -ForegroundColor Cyan
    $r.apps | ForEach-Object {
      $exe = if($_.exe -and (Test-Path $_.exe)){ $_.exe } else { '(sin binario)' }
      $flag = if($_.migrated){ ' [aislada]' } else { '' }
      Write-Host ("  {0,-24}{1}  {2}" -f $_.name, $flag, $exe)
    }
  }

  'audit' {
    Write-Host "=== AUDITORIA ===" -ForegroundColor Cyan
    $r = Get-Registry
    foreach($app in $r.apps){
      $ok  = @(); $bad = @()
      if($app.path       -and (Test-Path $app.path))       { $ok += 'path' }   else { $bad += 'path' }
      if($app.src_tauri  -and (Test-Path $app.src_tauri))  { $ok += 'src' }    else { $bad += 'src' }
      if($app.target_dir -and (Test-Path $app.target_dir)) { $ok += 'target' } else { $bad += 'target' }
      if($app.exe        -and (Test-Path $app.exe))        { $ok += 'exe' }    else { $bad += 'exe' }
      Write-Host ("  {0,-24} OK=[{1}]  FALTA=[{2}]" -f $app.name, ($ok -join ','), ($bad -join ','))
    }
  }

  'new' {
    if(-not $Name){ throw "Uso: forge new <nombre> [-Force]" }
    $src = "$ROOT\apps\_template"
    $dst = "$ROOT\apps\$Name"
    if(-not (Test-Path $src)){ throw "Falta el template: $src" }
    if((Test-Path $dst) -and -not $Force){ throw "Ya existe $dst (usa -Force)" }
    Copy-Item $src $dst -Recurse -Force
    Get-ChildItem $dst -Recurse -File | ForEach-Object {
      $txt = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if($txt -and $txt -match '__APPNAME__'){
        Set-Content $_.FullName -Value ($txt -replace '__APPNAME__',$Name) -Encoding UTF8 -NoNewline
      }
    }
    $r = Get-Registry
    $r.apps += [ordered]@{
      name       = $Name
      path       = $dst
      src_tauri  = "$dst\src-tauri"
      target_dir = "$dst\src-tauri\target"
      exe        = $null
      migrated   = $true
      last_build = $null
    }
    Save-Registry $r
    Write-Host "[OK] App creada: $dst" -ForegroundColor Green
  }

  'build' {
    if(-not $Name){ throw "Uso: forge build <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if(-not (Test-Path $app.src_tauri)){ throw "Falta src-tauri en $Name" }

    # target-dir ABSOLUTO, forzado por --target-dir (gana sobre env, workspace y config)
    $targetAbs = $app.target_dir
    if(-not (Test-Path $targetAbs)){ New-Item -ItemType Directory -Path $targetAbs -Force | Out-Null }

    # Neutralizar CARGO_TARGET_DIR heredado SOLO en este bloque
    $oldCTD = $env:CARGO_TARGET_DIR
    $env:CARGO_TARGET_DIR = $null

    Push-Location $app.src_tauri
    try {
      Write-Host "[forge] cargo build --release --target-dir `"$targetAbs`"" -ForegroundColor DarkGray
      & cargo build --release --target-dir $targetAbs
      if($LASTEXITCODE -ne 0){ throw "cargo build fallo con codigo $LASTEXITCODE" }
    } finally {
      Pop-Location
      if($oldCTD){ $env:CARGO_TARGET_DIR = $oldCTD }
    }

    # Localizar .exe en el target aislado
    $exe = Find-AppExe $targetAbs $Name

    if($exe){
      $r = Get-Registry
      $r.apps = $r.apps | ForEach-Object {
        if($_.name -eq $Name){
          $_.exe        = $exe
          $_.bin_name   = Split-Path $exe -Leaf
          $_.migrated   = $true
          $_.last_build = (Get-Date).ToString('o')
        }
        $_
      }
      Save-Registry $r
      Write-Host "[OK] Binario aislado: $exe" -ForegroundColor Green

      # Crear/actualizar acceso directo en el Escritorio real
      $lnkP = Join-Path $CFG.desktop "$Name.lnk"
      try {
        $ws  = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($lnkP)
        $lnk.TargetPath       = $exe
        $lnk.WorkingDirectory = Split-Path $exe -Parent
        $lnk.IconLocation     = "$exe,0"
        $lnk.Description      = "RUNEFORGE :: $Name"
        $lnk.Save()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
        Write-Host "[OK] Acceso directo: $lnkP" -ForegroundColor Green
      } catch { Write-Host "[WARN] No se pudo crear .lnk: $($_.Exception.Message)" }
    } else {
      Write-Host "[WARN] cargo OK pero sin .exe en $targetAbs" -ForegroundColor Yellow
      Write-Host "       Revisa si el crate solo produce lib (crate-type = [\"lib\"])." -ForegroundColor Yellow
    }
  }

  'run' {
    if(-not $Name){ throw "Uso: forge run <nombre>" }
    $app = Resolve-App $Name
    if(-not $app -or -not $app.exe -or -not (Test-Path $app.exe)){
      Write-Host "[forge] Sin binario, construyendo..." -ForegroundColor DarkGray
      & $PSCommandPath build $Name
      $app = Resolve-App $Name
    }
    if(-not $app.exe -or -not (Test-Path $app.exe)){
      throw "No hay binario para $Name"
    }
    $dir = Split-Path $app.exe -Parent
    Start-Process -FilePath $app.exe -WorkingDirectory $dir
    Write-Host "[OK] Lanzado: $($app.exe)" -ForegroundColor Green
  }

  'open' { & $PSCommandPath run $Name }

  'clean' {
    if(-not $Name){ throw "Uso: forge clean <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if($app.target_dir -and (Test-Path $app.target_dir)){
      Remove-Item $app.target_dir -Recurse -Force
      Write-Host "[OK] Limpiado: $($app.target_dir)" -ForegroundColor Green
    } else { Write-Host "[--] Nada que limpiar" }
  }

  default {
    Write-Host @"
FORGE CLI v1.1 - RUNEFORGE
Uso: forge <comando> [nombre] [-Force]

  list / audit
  new   <nombre>
  build <nombre>     (target-dir aislado, forzado)
  run   <nombre>
  clean <nombre>
"@
  }
} | Add-Member -NotePropertyName 'last_build' -NotePropertyValue (Get-Date).ToString('o') -Force
        }
        $_
      }
      Save-Registry $r
      Write-Host "[OK] Binario aislado: $exe" -ForegroundColor Green

      # Crear/actualizar acceso directo en el Escritorio real
      $lnkP = Join-Path $CFG.desktop "$Name.lnk"
      try {
        $ws  = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($lnkP)
        $lnk.TargetPath       = $exe
        $lnk.WorkingDirectory = Split-Path $exe -Parent
        $lnk.IconLocation     = "$exe,0"
        $lnk.Description      = "RUNEFORGE :: $Name"
        $lnk.Save()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($ws) | Out-Null
        Write-Host "[OK] Acceso directo: $lnkP" -ForegroundColor Green
      } catch { Write-Host "[WARN] No se pudo crear .lnk: $($_.Exception.Message)" }
    } else {
      Write-Host "[WARN] cargo OK pero sin .exe en $targetAbs" -ForegroundColor Yellow
      Write-Host "       Revisa si el crate solo produce lib (crate-type = [\"lib\"])." -ForegroundColor Yellow
    }
  }

  'run' {
    if(-not $Name){ throw "Uso: forge run <nombre>" }
    $app = Resolve-App $Name
    if(-not $app -or -not $app.exe -or -not (Test-Path $app.exe)){
      Write-Host "[forge] Sin binario, construyendo..." -ForegroundColor DarkGray
      & $PSCommandPath build $Name
      $app = Resolve-App $Name
    }
    if(-not $app.exe -or -not (Test-Path $app.exe)){
      throw "No hay binario para $Name"
    }
    $dir = Split-Path $app.exe -Parent
    Start-Process -FilePath $app.exe -WorkingDirectory $dir
    Write-Host "[OK] Lanzado: $($app.exe)" -ForegroundColor Green
  }

  'open' { & $PSCommandPath run $Name }

  'clean' {
    if(-not $Name){ throw "Uso: forge clean <nombre>" }
    $app = Resolve-App $Name
    if(-not $app){ throw "App no registrada: $Name" }
    if($app.target_dir -and (Test-Path $app.target_dir)){
      Remove-Item $app.target_dir -Recurse -Force
      Write-Host "[OK] Limpiado: $($app.target_dir)" -ForegroundColor Green
    } else { Write-Host "[--] Nada que limpiar" }
  }

  default {
    Write-Host @"
FORGE CLI v1.1 - RUNEFORGE
Uso: forge <comando> [nombre] [-Force]

  list / audit
  new   <nombre>
  build <nombre>     (target-dir aislado, forzado)
  run   <nombre>
  clean <nombre>
"@
  }
}
