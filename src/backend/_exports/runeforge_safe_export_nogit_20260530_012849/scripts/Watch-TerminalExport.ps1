# =====================================================================
# Watch-TerminalExport.ps1
# Vigila carpeta de exportaciones/transcripts y dispara importador.
# No requiere backend. No imprime secretos. No toca firewall.
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$Root = "C:\RUNEFOGE_PRO\runeforge"
$Source = "C:\Users\nesth\Documents\EL_ABISMO\PWSH RESULTADOS CODIGOS"
$Importer = Join-Path $Root "scripts\Import-LatestTerminalExport.ps1"
$Commander = Join-Path $Root "data\commander"
$Exports = Join-Path $Commander "exports"
$Archive = Join-Path $Exports "archive"
$Queue = Join-Path $Commander "queue\pending"
$Logs = Join-Path $Commander "logs"
$Trace = Join-Path $Commander "commander-trace.jsonl"
$State = Join-Path $Commander "watcher-state.json"
$LogFile = Join-Path $Logs "terminal-export-watcher.log"

foreach ($dir in @($Source,$Commander,$Exports,$Archive,$Queue,$Logs)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format s) $Message"
    Add-Content -LiteralPath $LogFile -Value $line -Encoding utf8
}

function Write-Trace {
    param(
        [string]$Action,
        [string]$File,
        [string]$Extra
    )

    $obj = [ordered]@{
        ts = (Get-Date).ToString("s")
        action = $Action
        file = $File
        extra = $Extra
        source = "watch-terminal-export"
    }

    Add-Content -LiteralPath $Trace -Value ($obj | ConvertTo-Json -Compress) -Encoding utf8
}

function Get-LatestSourceFile {
    Get-ChildItem -LiteralPath $Source -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in ".txt",".log",".md",".json" } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-Signature {
    param($File)

    if (-not $File) {
        return ""
    }

    return "$($File.FullName)|$($File.Length)|$($File.LastWriteTimeUtc.Ticks)"
}

Write-Log "WATCHER_START Source=$Source Importer=$Importer"
Write-Trace -Action "WATCHER_START" -File $Source -Extra "polling=2s"

$lastSignature = ""

while ($true) {
    try {
        $latest = Get-LatestSourceFile
        $sig = Get-Signature -File $latest

        if ($latest -and $sig -and $sig -ne $lastSignature) {
            Start-Sleep -Milliseconds 700

            $latest2 = Get-LatestSourceFile
            $sig2 = Get-Signature -File $latest2

            if ($sig2 -eq $sig) {
                $lastSignature = $sig

                Write-Log "IMPORT_TRIGGER file=$($latest2.FullName)"
                Write-Trace -Action "IMPORT_TRIGGER" -File $latest2.FullName -Extra "size=$($latest2.Length)"

                if (Test-Path -LiteralPath $Importer) {
                    pwsh -ExecutionPolicy Bypass -File $Importer -NoClipboard | Out-Null
                    Write-Log "IMPORT_OK file=$($latest2.FullName)"
                    Write-Trace -Action "IMPORT_OK" -File $latest2.FullName -Extra "latest updated"
                } else {
                    Write-Log "IMPORTER_MISSING path=$Importer"
                    Write-Trace -Action "IMPORTER_MISSING" -File $Importer -Extra "missing importer"
                }

                [ordered]@{
                    ts = (Get-Date).ToString("s")
                    lastFile = $latest2.FullName
                    lastSignature = $lastSignature
                    source = $Source
                    importer = $Importer
                    status = "RUNNING"
                } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $State -Encoding utf8 -Force
            }
        }
    } catch {
        Write-Log "ERROR $($_.Exception.Message)"
        Write-Trace -Action "WATCHER_ERROR" -File "" -Extra $_.Exception.Message
    }

    Start-Sleep -Seconds 2
}
