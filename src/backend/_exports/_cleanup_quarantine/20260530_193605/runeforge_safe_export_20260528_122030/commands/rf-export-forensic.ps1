param(
    [string]$Target = "C:\RUNEFOGE_PRO"
)

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[RF_EXPORT_FORENSIC][$ts]"

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Target)) {
    throw "No existe ruta: $Target"
}

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"

$OutDir = Join-Path $Target "runeforge\data\exports\forensic_$Stamp"

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$TreeFile = Join-Path $OutDir "TREE_FULL.txt"
$FilesFile = Join-Path $OutDir "FORENSIC_FILE_LIST.txt"
$SummaryFile = Join-Path $OutDir "FORENSIC_SUMMARY.json"

cmd /c tree "$Target" /F /A > $TreeFile

Get-ChildItem -LiteralPath $Target -Recurse -File -ErrorAction SilentlyContinue |
Where-Object {
    $_.FullName -notmatch '\\node_modules\\|\\\.git\\|\\bin\\|\\obj\\|\\dist\\|\\build\\|\\coverage\\'
} |
Select-Object FullName,Length,LastWriteTime |
Sort-Object FullName |
Format-Table -AutoSize |
Out-String -Width 4096 |
Set-Content -LiteralPath $FilesFile -Encoding utf8

$Summary = [ordered]@{
    timestamp = $ts
    target = $Target
    tree_file = $TreeFile
    forensic_file_list = $FilesFile
    total_files = (
        Get-ChildItem -LiteralPath $Target -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '\\node_modules\\|\\\.git\\|\\bin\\|\\obj\\|\\dist\\|\\build\\|\\coverage\\'
        }
    ).Count
    backend = "NO_TOCADO"
    mode = "READ_ONLY"
}

$Summary | ConvertTo-Json -Depth 6 |
Set-Content -LiteralPath $SummaryFile -Encoding utf8

Write-Host "`n[RF_EXPORT_FORENSIC_OK]" -ForegroundColor Green

[pscustomobject]@{
    Estado = "RF_EXPORT_FORENSIC_OK"
    Target = $Target
    Tree = $TreeFile
    Files = $FilesFile
    Summary = $SummaryFile
    Backend = "NO_TOCADO"
} | Format-List
