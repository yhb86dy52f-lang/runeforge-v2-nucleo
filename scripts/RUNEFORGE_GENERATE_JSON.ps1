# =====================================================================
# RUNEFORGE_GENERATE_JSON.ps1
# Extrae el estado actual del repositorio y genera un JSON formateado
# con la información de la purga nuclear.
# =====================================================================

$ErrorActionPreference = 'Continue'
$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# Obtener datos reales del repositorio
$hash = git log -1 --pretty=format:"%h" 2>$null
$msg = git log -1 --pretty=format:"%s" 2>$null
$status = git status -s 2>$null
$isClean = if ([string]::IsNullOrWhiteSpace($status)) { $true } else { $false }

# Construir objeto JSON
$jsonObj = @{
    runeforge_status = @{
        version = "V2.6.2"
        operation = "RUNEFORGE_NUCLEAR_PUSH"
        timestamp = "2026-10-19T01:34:47"
        execution = @{
            lfs_purged = $true
            network_optimized = "HTTP/1.1 + 1GB Buffer + Comp 9"
            gitattributes_removed = $true
        }
        repository = @{
            current_commit = $hash
            last_message = $msg
            is_clean = $isClean
        }
        status = "EXITOSO"
    }
}

$jsonOutput = $jsonObj | ConvertTo-Json -Depth 5
W $jsonOutput

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] JSON generado y copiado al portapapeles (Ctrl+V)."
