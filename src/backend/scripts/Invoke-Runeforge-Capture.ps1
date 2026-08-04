param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(
        "status",
        "exports-list",
        "backend-root",
        "package",
        "src-tree",
        "pm2-health",
        "v44-preflight"
    )]
    [string]$Preset
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = "C:\RUNEFOGE_PRO\runeforge"
$Backend = Join-Path $Root "app"
$Commander = Join-Path $Root "data\commander"
$Exports = Join-Path $Commander "exports"
$Trace = Join-Path $Commander "commander-trace.jsonl"
$Latest = Join-Path $Exports "latest-terminal-export.txt"
$Clean = Join-Path $Exports "latest-terminal-export.clean.txt"

foreach ($dir in @($Root,$Backend,$Commander,$Exports)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Add-RFTrace {
    param(
        [string]$Action,
        [string]$Preset,
        [string]$File,
        [string]$Status
    )

    $obj = [ordered]@{
        ts = (Get-Date).ToString("s")
        action = $Action
        preset = $Preset
        file = $File
        status = $Status
        source = "Invoke-Runeforge-Capture"
    }

    Add-Content -LiteralPath $Trace -Value ($obj | ConvertTo-Json -Compress) -Encoding utf8
}

function New-RFCapture {
    param(
        [string]$Name,
        [string]$CommandText,
        [scriptblock]$Script
    )

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName = $Name -replace "[^\w\-]+", "_"
    $outFile = Join-Path $Exports "capture_${stamp}_${safeName}.txt"

    $header = @"
# RUNEFORGE DIRECT COMMAND CAPTURE
timestamp=$((Get-Date).ToString("s"))
preset=$Name
command=$CommandText

--- OUTPUT ---
"@

    try {
        $result = & $Script *>&1 | Out-String -Width 320
        $status = "OK"
    } catch {
        $result = "[ERROR] $($_.Exception.Message)"
        $status = "ERROR"
    }

    $final = $header + "`r`n" + $result.Trim()

    Set-Content -LiteralPath $outFile -Value $final -Encoding utf8 -Force
    Set-Content -LiteralPath $Latest -Value $final -Encoding utf8 -Force
    Set-Content -LiteralPath $Clean -Value $final -Encoding utf8 -Force

    $meta = [ordered]@{
        timestamp = (Get-Date).ToString("s")
        preset = $Name
        outputFile = $outFile
        latest = $Latest
        clean = $Clean
        status = $status
    }

    $meta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $Exports "latest-terminal-export.json") -Encoding utf8 -Force

    Add-RFTrace -Action "CAPTURE" -Preset $Name -File $outFile -Status $status

    Write-Host "[OK] Captura generada:" -ForegroundColor Green
    Write-Host $outFile -ForegroundColor Cyan
    Write-Host "[OK] Latest clean actualizado:" -ForegroundColor Green
    Write-Host $Clean -ForegroundColor Cyan
}

switch ($Preset) {
    "status" {
        New-RFCapture -Name "status" -CommandText "Runeforge status summary" -Script {
            [ordered]@{
                User = (whoami)
                Host = (hostname)
                Path = (Get-Location).Path
                Root = "C:\RUNEFOGE_PRO\runeforge"
                Backend = "C:\RUNEFOGE_PRO\runeforge\app"
                RootExists = Test-Path "C:\RUNEFOGE_PRO\runeforge"
                BackendExists = Test-Path "C:\RUNEFOGE_PRO\runeforge\app"
                TailscaleIP = try { tailscale ip -4 | Select-Object -First 1 } catch { "NO_TAILSCALE" }
                Node = try { node -v } catch { "NO_NODE" }
                Npm = try { npm -v } catch { "NO_NPM" }
                Pm2 = try { pm2 -v } catch { "NO_PM2" }
                LatestClean = "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.clean.txt"
            } | ConvertTo-Json -Depth 6
        }
    }

    "exports-list" {
        New-RFCapture -Name "exports-list" -CommandText "List commander exports" -Script {
            Get-ChildItem "C:\RUNEFOGE_PRO\runeforge\data\commander\exports" -File |
                Sort-Object LastWriteTime -Descending |
                Select-Object Name,Length,LastWriteTime |
                Format-Table -AutoSize
        }
    }

    "backend-root" {
        New-RFCapture -Name "backend-root" -CommandText "List backend root without reading secrets" -Script {
            Get-ChildItem "C:\RUNEFOGE_PRO\runeforge\app" -Force |
                Select-Object Name,Mode,Length,LastWriteTime |
                Format-Table -AutoSize
        }
    }

    "package" {
        New-RFCapture -Name "package-json-summary" -CommandText "Read package.json summary" -Script {
            $pkg = Get-Content "C:\RUNEFOGE_PRO\runeforge\app\package.json" -Raw | ConvertFrom-Json
            $pkg | Select-Object name,type,scripts,dependencies,devDependencies | ConvertTo-Json -Depth 10
        }
    }

    "src-tree" {
        New-RFCapture -Name "src-tree" -CommandText "List src files" -Script {
            Get-ChildItem "C:\RUNEFOGE_PRO\runeforge\app\src" -Recurse -File |
                Select-Object FullName,Length,LastWriteTime |
                ConvertTo-Json -Depth 6
        }
    }

    "pm2-health" {
        New-RFCapture -Name "pm2-health-logs" -CommandText "PM2 + health + backend logs summary" -Script {
            Set-Location "C:\RUNEFOGE_PRO\runeforge\app"

            $pm2 = try {
                $raw = pm2 jlist 2>$null
                if ($raw) {
                    $json = $raw | ConvertFrom-Json
                    @($json | ForEach-Object {
                        [pscustomobject]@{
                            name = $_.name
                            pid = $_.pid
                            status = $_.pm2_env.status
                            cwd = $_.pm2_env.pm_cwd
                            script = $_.pm2_env.pm_exec_path
                            restarts = $_.pm2_env.restart_time
                        }
                    })
                } else {
                    @()
                }
            } catch {
                "NO_PM2_OR_PARSE_ERROR: $($_.Exception.Message)"
            }

            $health = try {
                Invoke-RestMethod "http://127.0.0.1:3100/health"
            } catch {
                [pscustomobject]@{
                    ok = $false
                    error = $_.Exception.Message
                }
            }

            $logs = Get-ChildItem ".\backend*.log" -ErrorAction SilentlyContinue |
                Select-Object Name,Length,LastWriteTime

            [ordered]@{
                pm2 = $pm2
                health = $health
                logs = $logs
            } | ConvertTo-Json -Depth 8
        }
    }

    "v44-preflight" {
        New-RFCapture -Name "v44-preflight-bundle" -CommandText "V44 backend preflight bundle" -Script {
            Set-Location "C:\RUNEFOGE_PRO\runeforge\app"

            $pkg = try {
                Get-Content ".\package.json" -Raw |
                    ConvertFrom-Json |
                    Select-Object name,type,scripts,dependencies,devDependencies
            } catch {
                [pscustomobject]@{ error = $_.Exception.Message }
            }

            $src = try {
                Get-ChildItem ".\src" -Recurse -File |
                    Select-Object FullName,Length,LastWriteTime
            } catch {
                @([pscustomobject]@{ error = $_.Exception.Message })
            }

            $pm2 = try {
                $raw = pm2 jlist 2>$null
                if ($raw) {
                    $json = $raw | ConvertFrom-Json
                    @($json | ForEach-Object {
                        [pscustomobject]@{
                            name = $_.name
                            pid = $_.pid
                            status = $_.pm2_env.status
                            cwd = $_.pm2_env.pm_cwd
                            script = $_.pm2_env.pm_exec_path
                            restarts = $_.pm2_env.restart_time
                        }
                    })
                } else {
                    @()
                }
            } catch {
                "NO_PM2_OR_PARSE_ERROR: $($_.Exception.Message)"
            }

            $health = try {
                Invoke-RestMethod "http://127.0.0.1:3100/health"
            } catch {
                [pscustomobject]@{
                    ok = $false
                    error = $_.Exception.Message
                }
            }

            $logs = Get-ChildItem ".\backend*.log" -ErrorAction SilentlyContinue |
                Select-Object Name,Length,LastWriteTime

            [ordered]@{
                generatedAt = (Get-Date).ToString("s")
                root = "C:\RUNEFOGE_PRO\runeforge"
                backend = "C:\RUNEFOGE_PRO\runeforge\app"
                package = $pkg
                srcFiles = $src
                pm2 = $pm2
                health = $health
                logs = $logs
                note = "No se leyó .env ni secretos."
            } | ConvertTo-Json -Depth 10
        }
    }
}
