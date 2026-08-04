# =====================================================================
# Start-Runeforge-Shell.ps1
# V43.1 FIX - PowerShell AutoTranscript + funciones globales persistentes
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$global:RF_ROOT = "C:\RUNEFOGE_PRO\runeforge"
$global:RF_BACKEND = "C:\RUNEFOGE_PRO\runeforge\app"
$global:RF_EXPORT_SOURCE = "C:\Users\nesth\Documents\EL_ABISMO\PWSH RESULTADOS CODIGOS"
$global:RF_IMPORTER = "C:\RUNEFOGE_PRO\runeforge\scripts\Import-LatestTerminalExport.ps1"
$global:RF_LATEST = "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.txt"

foreach ($dir in @($global:RF_ROOT, $global:RF_BACKEND, $global:RF_EXPORT_SOURCE, (Split-Path $global:RF_LATEST -Parent))) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$global:RUNEFORGE_TRANSCRIPT_PATH = Join-Path $global:RF_EXPORT_SOURCE "RUNEFORGE_SESSION_$stamp.txt"
$env:RUNEFORGE_TRANSCRIPT_PATH = $global:RUNEFORGE_TRANSCRIPT_PATH

try {
    Start-Transcript -Path $global:RUNEFORGE_TRANSCRIPT_PATH -Append -Force -IncludeInvocationHeader | Out-Null
} catch {
    Write-Host "[WARN] No se pudo iniciar transcript: $($_.Exception.Message)" -ForegroundColor Yellow
}

function global:rf-log {
    Write-Host $global:RUNEFORGE_TRANSCRIPT_PATH -ForegroundColor Cyan
}

function global:rf-tail {
    param([int]$Lines = 80)
    if (Test-Path -LiteralPath $global:RUNEFORGE_TRANSCRIPT_PATH) {
        Get-Content -LiteralPath $global:RUNEFORGE_TRANSCRIPT_PATH -Tail $Lines
    } else {
        Write-Host "[PENDIENTE] Transcript aún no existe." -ForegroundColor Yellow
    }
}

function global:rf-export {
    if (Test-Path -LiteralPath $global:RF_IMPORTER) {
        pwsh -ExecutionPolicy Bypass -File $global:RF_IMPORTER
    } else {
        Write-Host "[ERROR] No existe importador: $global:RF_IMPORTER" -ForegroundColor Red
    }
}

function global:rf-stoplog {
    try {
        Stop-Transcript | Out-Null
        Write-Host "[OK] Transcript detenido." -ForegroundColor Green
        Write-Host "[LOG] $global:RUNEFORGE_TRANSCRIPT_PATH" -ForegroundColor Cyan
    } catch {
        Write-Host "[WARN] Transcript no estaba activo o ya fue detenido." -ForegroundColor Yellow
    }
}

function global:rf-status {
    $tailscaleIp = "NO_TAILSCALE"
    try {
        $tailscaleIp = (tailscale ip -4 2>$null | Select-Object -First 1)
        if ([string]::IsNullOrWhiteSpace($tailscaleIp)) { $tailscaleIp = "NO_TAILSCALE_IP" }
    } catch {
        $tailscaleIp = "NO_TAILSCALE"
    }

    $status = [pscustomobject]@{
        User = (whoami)
        Host = (hostname)
        Path = (Get-Location).Path
        RootExists = (Test-Path -LiteralPath $global:RF_ROOT)
        BackendExists = (Test-Path -LiteralPath $global:RF_BACKEND)
        TailscaleIP = $tailscaleIp
        Transcript = $global:RUNEFORGE_TRANSCRIPT_PATH
        LatestExport = $global:RF_LATEST
    }

    $status | ConvertTo-Json -Depth 4
}

function global:rf-help {
    Write-Host ""
    Write-Host "Runeforge V43.3 comandos seguros:" -ForegroundColor Green
    Write-Host "  rf-status  -> estado JSON"
    Write-Host "  rf-log     -> ruta transcript activo"
    Write-Host "  rf-tail    -> últimas líneas capturadas"
    Write-Host "  rf-export  -> importar último transcript/export a Commander"
    Write-Host "  rf-stoplog -> detener transcript"
    Write-Host ""
}

Set-Location $global:RF_ROOT

Write-Host ""
Write-Host "--- NÚCLEO RUNEFORGE ACTIVO ---" -ForegroundColor Green
Write-Host "Root:       $global:RF_ROOT" -ForegroundColor Cyan
Write-Host "Backend:    $global:RF_BACKEND" -ForegroundColor Cyan
Write-Host "Transcript: $global:RUNEFORGE_TRANSCRIPT_PATH" -ForegroundColor Cyan
Write-Host ""
rf-help

# =====================================================================
# RUNEFORGE V43.2 SAFE EXPORT OVERRIDES
# Estas funciones sobreescriben las anteriores para evitar pegado accidental.
# =====================================================================

function global:rf-export {
    if (Test-Path -LiteralPath $global:RF_IMPORTER) {
        pwsh -ExecutionPolicy Bypass -File $global:RF_IMPORTER -NoClipboard
        Write-Host "[OK] Export importado sin copiar al portapapeles." -ForegroundColor Green
        Write-Host "[TIP] Usa rf-copylatest si quieres copiarlo manualmente." -ForegroundColor Yellow
    } else {
        Write-Host "[ERROR] No existe importador: $global:RF_IMPORTER" -ForegroundColor Red
    }
}

function global:rf-copylatest {
    if (Test-Path -LiteralPath $global:RF_LATEST) {
        Get-Content -LiteralPath $global:RF_LATEST -Raw | Set-Clipboard
        Write-Host "[OK] latest-terminal-export copiado al portapapeles." -ForegroundColor Green
    } else {
        Write-Host "[PENDIENTE] No existe latest export: $global:RF_LATEST" -ForegroundColor Yellow
    }
}

function global:rf-latest {
    param([int]$Lines = 80)

    if (Test-Path -LiteralPath $global:RF_LATEST) {
        Get-Content -LiteralPath $global:RF_LATEST -Tail $Lines
    } else {
        Write-Host "[PENDIENTE] No existe latest export: $global:RF_LATEST" -ForegroundColor Yellow
    }
}

function global:rf-openlatest {
    if (Test-Path -LiteralPath $global:RF_LATEST) {
        Start-Process $global:RF_LATEST
    } else {
        Write-Host "[PENDIENTE] No existe latest export: $global:RF_LATEST" -ForegroundColor Yellow
    }
}

function global:rf-done {
    try {
        Stop-Transcript | Out-Null
        Write-Host "[OK] Transcript detenido." -ForegroundColor Green
    } catch {
        Write-Host "[WARN] Transcript no estaba activo o ya fue detenido." -ForegroundColor Yellow
    }

    if (Test-Path -LiteralPath $global:RF_IMPORTER) {
        pwsh -ExecutionPolicy Bypass -File $global:RF_IMPORTER -NoClipboard
        Write-Host "[OK] Último transcript importado sin copiar al portapapeles." -ForegroundColor Green
    }
}

function global:rf-help {
    Write-Host ""
    Write-Host "Runeforge V43.2 comandos seguros:" -ForegroundColor Green
    Write-Host "  rf-status      -> estado JSON"
    Write-Host "  rf-log         -> ruta transcript activo"
    Write-Host "  rf-tail        -> últimas líneas del transcript activo"
    Write-Host "  rf-export      -> importa último transcript SIN copiar"
    Write-Host "  rf-latest      -> muestra latest-terminal-export"
    Write-Host "  rf-copylatest  -> copia latest-terminal-export manualmente"
    Write-Host "  rf-openlatest  -> abre latest-terminal-export"
    Write-Host "  rf-done        -> detiene transcript + importa SIN copiar"
    Write-Host ""
}


# =====================================================================
# RUNEFORGE V43.3 CLEAN CAPTURE
# Limpia transcripts y permite capturar comandos puntuales sin ruido.
# =====================================================================

$global:RF_CLEAN_LATEST = "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.clean.txt"

function global:Convert-RFTranscriptClean {
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $lines = $Text -split "`r?`n"

    $skipPatterns = @(
        '^\*{5,}$',
        '^PowerShell transcript',
        '^Start time:',
        '^End time:',
        '^Username:',
        '^RunAs User:',
        '^Configuration Name:',
        '^Machine:',
        '^Host Application:',
        '^Process ID:',
        '^PSVersion:',
        '^PSEdition:',
        '^GitCommitId:',
        '^OS:',
        '^Platform:',
        '^PSCompatibleVersions:',
        '^PSRemotingProtocolVersion:',
        '^SerializationVersion:',
        '^WSManStackVersion:',
        '^Command start time:',
        '^CommandInvocation\(',
        '^ParameterBinding\(',
        '^\[RUNEFORGE\]$',
        '^\s*@ C:\\',
        '^\s*\[ADMIN\]$',
        '^>$',
        '^PS>',
        '^--- NÚCLEO RUNEFORGE ACTIVO ---$',
        '^Runeforge V43\.',
        '^\s+rf-status\s+->',
        '^\s+rf-log\s+->',
        '^\s+rf-tail\s+->',
        '^\s+rf-export\s+->',
        '^\s+rf-stoplog\s+->',
        '^\s+rf-copylatest',
        '^\s+rf-openlatest',
        '^\s+rf-done'
    )

    $cleanLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        $skip = $false

        foreach ($pattern in $skipPatterns) {
            if ($line -match $pattern) {
                $skip = $true
                break
            }
        }

        if (-not $skip) {
            $cleanLines.Add($line)
        }
    }

    $cleanText = ($cleanLines -join "`r`n")

    # Compactar exceso de líneas vacías.
    $cleanText = [regex]::Replace($cleanText, "(`r`n){3,}", "`r`n`r`n")

    return $cleanText.Trim()
}

function global:rf-cleanlatest {
    if (-not (Test-Path -LiteralPath $global:RF_LATEST)) {
        Write-Host "[PENDIENTE] No existe latest export: $global:RF_LATEST" -ForegroundColor Yellow
        return
    }

    $raw = Get-Content -LiteralPath $global:RF_LATEST -Raw
    $clean = Convert-RFTranscriptClean -Text $raw

    $header = @"
# RUNEFORGE CLEAN LATEST EXPORT
timestamp=$((Get-Date).ToString("s"))
source=$global:RF_LATEST

--- CLEAN OUTPUT ---
"@

    Set-Content -LiteralPath $global:RF_CLEAN_LATEST -Value ($header + "`r`n" + $clean) -Encoding utf8 -Force

    Write-Host "[OK] Clean latest generado:" -ForegroundColor Green
    Write-Host $global:RF_CLEAN_LATEST -ForegroundColor Cyan
}

function global:rf-copyclean {
    if (-not (Test-Path -LiteralPath $global:RF_CLEAN_LATEST)) {
        rf-cleanlatest
    }

    if (Test-Path -LiteralPath $global:RF_CLEAN_LATEST) {
        Get-Content -LiteralPath $global:RF_CLEAN_LATEST -Raw | Set-Clipboard
        Write-Host "[OK] Clean latest copiado al portapapeles." -ForegroundColor Green
    }
}

function global:rf-openclean {
    if (-not (Test-Path -LiteralPath $global:RF_CLEAN_LATEST)) {
        rf-cleanlatest
    }

    if (Test-Path -LiteralPath $global:RF_CLEAN_LATEST) {
        Start-Process $global:RF_CLEAN_LATEST
    }
}

function global:rf-cap {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Script
    )

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outFile = "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\capture_$stamp.txt"

    $cmdText = $Script.ToString()

    $header = @"
# RUNEFORGE DIRECT COMMAND CAPTURE
timestamp=$((Get-Date).ToString("s"))
command=$cmdText

--- OUTPUT ---
"@

    try {
        $result = & $Script *>&1 | Out-String
    } catch {
        $result = "[ERROR] $($_.Exception.Message)"
    }

    $final = $header + "`r`n" + $result.Trim()

    Set-Content -LiteralPath $outFile -Value $final -Encoding utf8 -Force
    Set-Content -LiteralPath $global:RF_LATEST -Value $final -Encoding utf8 -Force
    Set-Content -LiteralPath $global:RF_CLEAN_LATEST -Value $final -Encoding utf8 -Force

    Write-Host "[OK] Captura directa generada:" -ForegroundColor Green
    Write-Host $outFile -ForegroundColor Cyan
    Write-Host "[OK] También actualizado latest y clean latest." -ForegroundColor Green
}

function global:rf-help {
    Write-Host ""
    Write-Host "Runeforge V43.3 comandos seguros:" -ForegroundColor Green
    Write-Host "  rf-status             -> estado JSON"
    Write-Host "  rf-log                -> ruta transcript activo"
    Write-Host "  rf-tail               -> últimas líneas del transcript activo"
    Write-Host "  rf-export             -> importa último transcript SIN copiar"
    Write-Host "  rf-latest 40          -> muestra latest-terminal-export"
    Write-Host "  rf-cleanlatest        -> genera latest limpio para IA"
    Write-Host "  rf-copyclean          -> copia latest limpio manualmente"
    Write-Host "  rf-openclean          -> abre latest limpio"
    Write-Host "  rf-cap { comando }    -> captura limpia de un comando puntual"
    Write-Host "  rf-done               -> detiene transcript + importa SIN copiar"
    Write-Host ""
}


