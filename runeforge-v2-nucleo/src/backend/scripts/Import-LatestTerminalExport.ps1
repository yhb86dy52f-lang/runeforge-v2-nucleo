param(
    [int]$MaxChars = 180000,
    [switch]$NoClipboard,
    [switch]$OpenAfter
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ExportSource = "C:\Users\nesth\Documents\EL_ABISMO\PWSH RESULTADOS CODIGOS"
$Root = "C:\RUNEFOGE_PRO\runeforge"
$Commander = Join-Path $Root "data\commander"
$ExportsData = Join-Path $Commander "exports"
$TracePath = Join-Path $Commander "commander-trace.jsonl"
$LatestTxt = Join-Path $ExportsData "latest-terminal-export.txt"
$LatestJson = Join-Path $ExportsData "latest-terminal-export.json"

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Clean-TerminalText {
    param([string]$Text)

    if ($null -eq $Text) { return "" }

    $esc = [char]27
    $Text = [regex]::Replace($Text, "$esc\[[0-?]*[ -/]*[@-~]", "")
    $Text = $Text -replace "`0", ""
    $Text = $Text -replace "`r`n", "`n"
    $Text = $Text -replace "`r", "`n"
    $Text = $Text -replace "`n", "`r`n"

    return $Text.Trim()
}

function Read-TextFileSafe {
    param([string]$Path)

    try {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    } catch {
        try {
            return Get-Content -LiteralPath $Path -Raw -Encoding Default
        } catch {
            return "[ERROR] No se pudo leer archivo: $Path`r`n$($_.Exception.Message)"
        }
    }
}

function Write-Trace {
    param(
        [string]$Action,
        [string]$File,
        [string]$Extra
    )

    Ensure-Dir (Split-Path $TracePath -Parent)

    $line = [ordered]@{
        ts = (Get-Date).ToString("s")
        action = $Action
        file = $File
        extra = $Extra
        source = "Import-LatestTerminalExport"
    } | ConvertTo-Json -Compress

    Add-Content -LiteralPath $TracePath -Value $line -Encoding utf8
}

Ensure-Dir $ExportSource
Ensure-Dir $ExportsData

$Latest = Get-ChildItem -LiteralPath $ExportSource -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in ".txt",".log",".md",".json" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $Latest) {
    $msg = "[PENDIENTE] No hay archivos exportados/transcripts en: $ExportSource"
    Write-Host $msg -ForegroundColor Yellow
    Write-Trace -Action "TERMINAL_EXPORT_IMPORT_EMPTY" -File "" -Extra $msg
    return
}

$raw = Read-TextFileSafe -Path $Latest.FullName
$clean = Clean-TerminalText -Text $raw

$truncated = $false
if ($clean.Length -gt $MaxChars) {
    $clean = $clean.Substring(0, $MaxChars) + "`r`n`r`n...[TRUNCADO_POR_RUNEFORGE maxChars=$MaxChars]..."
    $truncated = $true
}

$header = @"
# RUNEFORGE TERMINAL EXPORT IMPORT
timestamp=$((Get-Date).ToString("s"))
source=$($Latest.FullName)
file=$($Latest.Name)
lastWrite=$($Latest.LastWriteTime.ToString("s"))
sizeBytes=$($Latest.Length)
truncated=$truncated

--- OUTPUT ---
"@

$final = $header + "`r`n" + $clean

Set-Content -LiteralPath $LatestTxt -Value $final -Encoding utf8 -Force

$meta = [ordered]@{
    timestamp = (Get-Date).ToString("s")
    sourceFolder = $ExportSource
    sourceFile = $Latest.FullName
    fileName = $Latest.Name
    lastWriteTime = $Latest.LastWriteTime.ToString("s")
    sizeBytes = $Latest.Length
    outputFile = $LatestTxt
    truncated = $truncated
    copiedToClipboard = -not $NoClipboard.IsPresent
}

$meta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $LatestJson -Encoding utf8 -Force

if (-not $NoClipboard.IsPresent) {
    Set-Clipboard -Value $final
}

Write-Trace -Action "TERMINAL_EXPORT_IMPORTED" -File $Latest.FullName -Extra "truncated=$truncated; clipboard=$(-not $NoClipboard.IsPresent)"

Write-Host "`n[OK] Última exportación/transcript importado." -ForegroundColor Green
Write-Host "[SOURCE] $($Latest.FullName)" -ForegroundColor Cyan
Write-Host "[OUTPUT] $LatestTxt" -ForegroundColor Cyan
Write-Host "[META]   $LatestJson" -ForegroundColor Cyan

if (-not $NoClipboard.IsPresent) {
    Write-Host "[OK] Resultado copiado al portapapeles." -ForegroundColor Green
}

if ($OpenAfter.IsPresent) {
    Start-Process $LatestTxt
}
