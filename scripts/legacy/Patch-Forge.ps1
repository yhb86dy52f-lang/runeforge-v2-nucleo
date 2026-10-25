#Requires -Version 5.1
# Patch-Forge.ps1 - Corrige la asignacion a bin_name en forge.ps1

$ErrorActionPreference = 'Stop'
$f = 'C:\RUNEFORGE_V2_CORE\scripts\forge.ps1'
if(-not (Test-Path $f)){ throw "No existe $f" }

# Backup una sola vez
$bak = "$f.bak"
if(-not (Test-Path $bak)){ Copy-Item $f $bak }

$src = Get-Content $f -Raw

$oldBlock = @'
        if($_.name -eq $Name){
          $_.exe        = $exe
          $_.bin_name   = Split-Path $exe -Leaf
          $_.migrated   = $true
          $_.last_build = (Get-Date).ToString('o')
        }
'@

$newBlock = @'
        if($_.name -eq $Name){
          $_ | Add-Member -NotePropertyName 'exe'        -NotePropertyValue $exe                     -Force
          $_ | Add-Member -NotePropertyName 'bin_name'   -NotePropertyValue (Split-Path $exe -Leaf)  -Force
          $_ | Add-Member -NotePropertyName 'migrated'   -NotePropertyValue $true                   -Force
          $_ | Add-Member -NotePropertyName 'last_build' -NotePropertyValue (Get-Date).ToString('o') -Force
        }
'@

if($src -match [regex]::Escape($oldBlock)){
  $src = $src -replace [regex]::Escape($oldBlock), $newBlock
  Set-Content -LiteralPath $f -Value $src -Encoding UTF8
  Write-Host "[OK] forge.ps1 parcheado (bin_name + Add-Member -Force en todas las asignaciones)." -ForegroundColor Green
  Write-Host "     Backup: $bak"
} else {
  Write-Host "[--] El bloque objetivo no coincide. Revisa manualmente:" -ForegroundColor Yellow
  Write-Host "     linea ~125 de $f"
}