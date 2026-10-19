$ErrorActionPreference = "Continue"
$Root = "C:\RUNEFORGE_V2_CORE"
$Apps = "$Root\apps"
$Freed = 0
$Report = @()
$Report += "=== PURGA DE TARGETS LOCALES ==="
$targets = Get-ChildItem "$Apps" -Recurse -Directory -Filter "target" -EA SilentlyContinue | Where-Object { $_.FullName -match '\\src-tauri\\target$' }
foreach ($t in $targets) {
    $s = (Get-ChildItem $t.FullName -Recurse -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($s -eq $null) { $s = 0 }
    $Report += "Borrando: $($t.FullName.Replace("$Root\",'')) ($([math]::Round($s/1GB,2)) GB)"
    Remove-Item $t.FullName -Recurse -Force -EA SilentlyContinue
    $Freed += $s
}
$Report += "`n=== EXES REALES ==="
Get-ChildItem "$Apps" -Recurse -Filter "*.exe" -File | Where-Object { $_.Name -notmatch 'build|script|_lib' } | ForEach-Object {
    $Report += ("{0,-40} : {1} MB" -f $_.Name, [math]::Round($_.Length/1MB,2))
}
$Report += "`n=== MOSQUITTO ==="
$Report += "Estado: $((Get-Service mosquitto -EA SilentlyContinue).Status)"
$Report += "`n=== ESPACIO LIBERADO: $([math]::Round($Freed/1GB,2)) GB ==="
$txt = $Report -join "`r`n"
Set-Clipboard -Value $txt
Write-Host $txt
