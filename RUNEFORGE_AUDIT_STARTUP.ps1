# =====================================================================
# RUNEFORGE_AUDIT_STARTUP.ps1
# Lista todo lo que arranca al iniciar sesion y detecta duplicados :3100
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "=== AUDIT STARTUP ==="
W "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W ""

# --- 1. Carpeta Startup del usuario ---
W "[1] Carpeta Startup (usuario)"
$startupUser = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
if (Test-Path $startupUser) {
    $items = @(Get-ChildItem $startupUser -ErrorAction SilentlyContinue)
    if ($items.Count -eq 0) { W "    (vacia)" }
    foreach ($i in $items) {
        W "    $($i.Name)"
        if ($i.Extension -eq '.lnk') {
            $sh = New-Object -ComObject WScript.Shell
            $lnk = $sh.CreateShortcut($i.FullName)
            W "      -> Target: $($lnk.TargetPath)"
            W "      -> Args:   $($lnk.Arguments)"
            W "      -> WorkDir:$($lnk.WorkingDirectory)"
        }
    }
} else { W "    (no existe)" }
W ""

# --- 2. Carpeta Startup comun ---
W "[2] Carpeta Startup (todos los usuarios)"
$startupCommon = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
if (Test-Path $startupCommon) {
    $items = @(Get-ChildItem $startupCommon -ErrorAction SilentlyContinue)
    if ($items.Count -eq 0) { W "    (vacia)" }
    foreach ($i in $items) {
        W "    $($i.Name)"
    }
} else { W "    (no existe)" }
W ""

# --- 3. Registry Run (usuario) ---
W "[3] Registry HKCU:\...\Run"
$rk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
if (Test-Path $rk) {
    $props = Get-ItemProperty -Path $rk
    $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
        W "    $($_.Name) = $($_.Value)"
    }
} else { W "    (no existe)" }
W ""

# --- 4. Registry Run (maquina) ---
W "[4] Registry HKLM:\...\Run"
$rk2 = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
if (Test-Path $rk2) {
    $props2 = Get-ItemProperty -Path $rk2
    $props2.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
        W "    $($_.Name) = $($_.Value)"
    }
} else { W "    (no existe)" }
W ""

# --- 5. Tareas programadas con trigger "At logon" ---
W "[5] Tareas programadas (logon)"
try {
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $_.Triggers | Where-Object { $_.CimClass.CimClassName -match 'LogonTrigger' }
    }
    foreach ($t in $tasks) {
        $info = Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue
        W "    [$($t.State)] $($t.TaskPath)$($t.TaskName)"
    }
} catch { W "    (no se pudo enumerar)" }
W ""

# --- 6. Quien tiene ahora :3100 ---
W "[6] Puerto :3100 ahora"
$conn = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction SilentlyContinue
foreach ($c in $conn) {
    $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
    if ($p) {
        $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)").CommandLine
        W "    PID $($p.Id)  $($p.ProcessName)  $([math]::Round($p.WorkingSet/1MB,1))MB"
        W "    cmd: $cmd"
    }
}
W ""

# --- 7. Procesos node con parent info ---
W "[7] Procesos node"
$nodes = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue)
foreach ($n in $nodes) {
    $parent = Get-Process -Id $n.ParentProcessId -ErrorAction SilentlyContinue
    $cmd = $n.CommandLine
    if ($cmd.Length -gt 120) { $cmd = $cmd.Substring(0,120) + '...' }
    W "    PID $($n.ProcessId)  parent=$($parent.ProcessName)($($n.ParentProcessId))"
    W "      $cmd"
}

W ""
W "=== FIN ==="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "[OK] Copiado al portapapeles."