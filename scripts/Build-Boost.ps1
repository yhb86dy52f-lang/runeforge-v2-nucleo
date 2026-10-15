# C:\RUNEFORGE_V2_CORE\scripts\Build-Boost.ps1
# RUNEFORGE BUILD BOOST v4.0 - Optimizador para compilacion Rust/Tauri
# Mata solo lo que roba CPU/RAM y protege toolchain Rust + terminal
# Uso: .\scripts\Build-Boost.ps1  (antes de compilar)

[CmdletBinding()]
param(
    [switch]$Agresivo,  # Cierra tambien Discord/Spotify/Teams
    [switch]$NoServicios
)

$ErrorActionPreference = 'SilentlyContinue'
$Host.UI.RawUI.WindowTitle = "RUNEFORGE BUILD BOOST v4.0"
$startRAM = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)

Write-Host @"
==============================================
   RUNEFORGE BUILD BOOST v4.0
   Optimizado para cargo build --release
   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
==============================================
"@ -ForegroundColor Cyan

# PROCESOS SAGRADOS - NUNCA MATAR
$Protegidos = @(
    # Sistema
    'System','Idle','Registry','Memory Compression','smss','csrss','wininit','services','lsass','svchost',
    'explorer','dwm','taskhostw','winlogon','fontdrvhost','spoolsv','audiodg','WmiPrvSE',
    'SecurityHealthService','SecurityHealthSystray','SgrmBroker','RuntimeBroker',
    # Terminal y IDE
    'powershell','pwsh','conhost','cmd','WindowsTerminal','wt','openconsole',
    'Code','code','cursor','Cursor',
    # Toolchain Rust / Tauri - CRITICO
    'cargo','rustc','rustup','sccache','link','cl','mspdbsrv','msbuild','devenv',
    'tauri','node','npm','pnpm','yarn','esbuild','vite',
    # Mosquitto y tu stack
    'mosquitto','arduino-cli','esp32-scanner-pro','dictate-studio-v2'
)

# LISTA NEGRA - lo que SI mata
$BlackList = @(
    # Navegadores - los mas pesados
    'chrome','msedge','firefox','brave','opera','vivaldi',
    # Chat / Electron pesados
    'Discord','slack','Teams','Telegram','WhatsApp','Signal',
    # Media / Launchers
    'Spotify','steam','EpicGamesLauncher','RiotClient',
    # Adobe / pesados
    'Photoshop','Illustrator','Premiere','AfterFX'
)

if ($Agresivo) {
    $BlackList += @('msedgewebview2','SearchApp','Widgets','OneDrive')
}

$matados = 0
$ramLiberada = 0

Write-Host "`n[1/4] Matando procesos pesados..." -ForegroundColor Yellow

# Matar por BlackList primero
foreach ($name in $BlackList) {
    Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Id -ne $PID -and $_.ProcessName -notin $Protegidos) {
            $ram = [math]::Round($_.WorkingSet64 / 1MB, 1)
            try { 
                Stop-Process -Id $_.Id -Force -ErrorAction Stop
                $matados++; $ramLiberada += $ram
                Write-Host "  [OK] $name (PID $($_.Id)) - ${ram} MB" -ForegroundColor Green
            } catch {}
        }
    }
}

# Luego procesos con >300MB que no sean protegidos (limite alto para no tocar VS Code si lo usas)
Get-Process | Where-Object { 
    $_.Id -ne $PID -and 
    $_.ProcessName -notin $Protegidos -and 
    $_.ProcessName -notin $BlackList -and
    $_.WorkingSet64 / 1MB -gt 350 
} | Sort-Object WorkingSet64 -Descending | ForEach-Object {
    $ram = [math]::Round($_.WorkingSet64 / 1MB, 1)
    try {
        Stop-Process -Id $_.Id -Force
        $matados++; $ramLiberada += $ram
        Write-Host "  [OK] $($_.ProcessName) (PID $($_.Id)) - ${ram} MB [>350MB]" -ForegroundColor DarkYellow
    } catch {}
}

Write-Host ">> Matados: $matados | RAM liberada: $([math]::Round($ramLiberada,1)) MB" -ForegroundColor Cyan

Write-Host "`n[2/4] Compactando memoria..." -ForegroundColor Yellow
Add-Type -Namespace Win32 -Name Memory -MemberDefinition '[DllImport("kernel32.dll", SetLastError = true)] public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);'
$compact = 0
Get-Process | Where-Object { $_.Id -ne 0 -and $_.Id -ne 4 -and $_.WorkingSet64 / 1MB -gt 80 -and $_.ProcessName -in $Protegidos } | ForEach-Object {
    try { [Win32.Memory]::SetProcessWorkingSetSize($_.Handle, -1, -1) | Out-Null; $compact++ } catch {}
}
Write-Host "  Compactados: $compact procesos del toolchain" -ForegroundColor Green

Write-Host "`n[3/4] Power plan + prioridad compilador..." -ForegroundColor Yellow
try {
    # Poner en Alto Rendimiento
    $high = (powercfg /list | Select-String "Alto rendimiento" | ForEach-Object { ($_ -split ":")[1].Trim().Split()[0] } | Select-Object -First 1)
    if ($high) { powercfg /setactive $high; Write-Host "  [OK] Power plan: Alto rendimiento" -ForegroundColor Green }
} catch {}

# Subir prioridad a cargo/rustc si estan corriendo
Get-Process -Name "cargo","rustc","link" -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.PriorityClass = "High"; Write-Host "  [OK] Prioridad alta: $($_.ProcessName) PID $($_.Id)" -ForegroundColor Green } catch {}
}

Write-Host "`n[4/4] Limpieza rapida (sin tocar target ni .sccache)..." -ForegroundColor Yellow
$tempFreed = 0
@("$env:TEMP","$env:WINDIR\Temp") | ForEach-Object {
    if (Test-Path $_) {
        $files = Get-ChildItem $_ -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) -and $_.FullName -notlike "*RUNEFORGE_V2_CORE*" -and $_.FullName -notlike "*sccache*" -and $_.FullName -notlike "*cargo*" }
        $size = ($files | Measure-Object Length -Sum).Sum
        $files | Remove-Item -Force -ErrorAction SilentlyContinue
        $tempFreed += $size
    }
}
Write-Host "  Temp liberado: $([math]::Round($tempFreed/1MB,2)) MB (protegiendo .sccache y target)" -ForegroundColor Green

if (-not $NoServicios) {
    Write-Host "`n[Extra] Pausando servicios pesados (temporal)..." -ForegroundColor Yellow
    @('WSearch','SysMain','DiagTrack') | ForEach-Object {
        $svc = Get-Service $_ -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq 'Running') {
            try { Stop-Service $_ -Force -ErrorAction Stop; Write-Host "  [OK] Servicio pausado: $_" -ForegroundColor DarkGray } catch {}
        }
    }
}

$endRAM = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
$gained = [math]::Round($endRAM - $startRAM,2)

Write-Host @"

==============================================
 RESUMEN BUILD BOOST
==============================================
 Procesos matados:        $matados
 RAM liberada procesos:   $([math]::Round($ramLiberada,1)) MB
 Temp liberado:           $([math]::Round($tempFreed/1MB,2)) MB
 RAM libre antes:         ${startRAM} GB
 RAM libre ahora:         ${endRAM} GB
 MEJORA NETA:             ${gained} GB
==============================================
 Listo para: cargo build --release

 Protegido: cargo, rustc, sccache, link, tauri, node, terminal, VS Code
 Borrado: Chrome, Edge, Discord, Spotify, etc.
 NO se toco: C:\RUNEFORGE_V2_CORE\target y .sccache
==============================================
"@ -ForegroundColor Cyan
