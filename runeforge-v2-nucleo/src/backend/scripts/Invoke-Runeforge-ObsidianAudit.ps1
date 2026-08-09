$ts=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[RUNEFORGE_OBSIDIAN_AUDIT_SCRIPT][$ts]"
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)

$roots=@(
  "C:\RUNEFOGE_PRO",
  "C:\Users\nesth\Documents\EL_ABISMO",
  "$env:USERPROFILE\Documents",
  "$env:USERPROFILE\Desktop",
  "$env:USERPROFILE\Downloads"
) | Where-Object { Test-Path -LiteralPath $_ }

Write-Host "`n[OBSIDIAN_PROCESS]"
$proc=Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue
if($proc){
  $proc | Select-Object ProcessName,Id,@{n="RAM_MB";e={[math]::Round($_.WorkingSet64/1MB,1)}},Path | Format-Table -AutoSize
}else{
  Write-Host "[INFO] Obsidian no está corriendo." -ForegroundColor Yellow
}

Write-Host "`n[OBSIDIAN_INSTALL]"
$cmd=Get-Command Obsidian.exe -ErrorAction SilentlyContinue
$pf86=${env:ProgramFiles(x86)}
$candidates=@(
  "$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe",
  "$env:ProgramFiles\Obsidian\Obsidian.exe",
  "$pf86\Obsidian\Obsidian.exe"
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

if($cmd){
  $cmd | Select-Object Source,Version | Format-List
}elseif($candidates){
  $candidates | ForEach-Object { Get-Item -LiteralPath $_ | Select-Object FullName,Length,LastWriteTime | Format-List }
}else{
  Write-Host "[PENDIENTE] No encontré Obsidian.exe en rutas conocidas." -ForegroundColor Yellow
}

Write-Host "`n[VAULT_CANDIDATES]"
$vaults=Get-ChildItem -Path $roots -Directory -Recurse -Force -ErrorAction SilentlyContinue |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName ".obsidian") } |
  Select-Object FullName,LastWriteTime

if($vaults){
  $vaults | Sort-Object LastWriteTime -Descending | Format-Table -AutoSize
}else{
  Write-Host "[PENDIENTE] No encontré carpetas con .obsidian en rutas auditadas." -ForegroundColor Yellow
}

Write-Host "`n[RUNEFORGE_MEMORY_PATHS]"
$paths=@(
  "C:\RUNEFOGE_PRO\runeforge",
  "C:\RUNEFOGE_PRO\runeforge\scripts",
  "C:\RUNEFOGE_PRO\runeforge\data",
  "C:\Users\nesth\Documents\EL_ABISMO",
  "C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO",
  "C:\Users\nesth\Documents\EL_ABISMO\01_MEMORIAS"
)

$memPaths=foreach($p in $paths){
  [pscustomobject]@{Path=$p;Exists=(Test-Path -LiteralPath $p)}
}
$memPaths | Format-Table -AutoSize

Write-Host "`n[MARKDOWN_COUNTS]"
$mdCounts=foreach($r in $roots){
  $count=(Get-ChildItem -Path $r -Filter *.md -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
  [pscustomobject]@{Root=$r;MarkdownFiles=$count}
}
$mdCounts | Format-Table -AutoSize

Write-Host "`n[SUMMARY]"
[pscustomobject]@{
  Estado="OBSIDIAN_AUDIT_SCRIPT_DONE"
  Script=$PSCommandPath
  Backend="NO_TOCADO"
  Runeforge="NO_TOCADO"
  Modo="SOLO_LECTURA"
  Siguiente="Crear bridge si vault/rutas están claras"
} | Format-List
