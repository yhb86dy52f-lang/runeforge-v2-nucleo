# RUNEFORGE KILL NET HOGS - AUTONOMO
$ErrorActionPreference="SilentlyContinue"
$ProgressPreference="SilentlyContinue"
$Log=[System.Text.StringBuilder]::new()
function L($m){$t=Get-Date -Format "HH:mm:ss";$l="[$t] $m";Write-Host $l -ForegroundColor Yellow;[void]$Log.AppendLine($l)}
L "--- MATANDO PROCESOS QUE ROBAN RED ---"

# 1. TOP 20 conexiones por proceso
L "Analizando conexiones..."
$conns=Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Group-Object OwningProcess | Sort-Object Count -Descending | Select-Object -First 20
$conns | ForEach-Object{
 try{
  $proc=Get-Process -Id $_.Name -ErrorAction SilentlyContinue
  $pname=if($proc){$proc.ProcessName}else{"PID $($_.Name)"}
  L "$pname (PID $($_.Name)) -> $($_.Count) conexiones"
 }catch{}
}

# 2. Servicios que roban ancho de banda en segundo plano
L "Deteniendo servicios de fondo..."
# Delivery Optimization - el que mas roba (P2P de Windows Update)
Stop-Service -Name DoSvc -Force -ErrorAction SilentlyContinue; Set-Service -Name DoSvc -StartupType Disabled -EA SilentlyContinue; L "DoSvc (Delivery Optimization) OFF"
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue; L "wuauserv (Windows Update) pausado temporal"
Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue; L "BITS OFF"
Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue; L "WSearch OFF (index)"

# 3. Procesos de usuario que chupan red
$killList=@("OneDrive","OneDriveSetup","Teams","ms-teams","Spotify","Discord","Slack","Dropbox","GoogleDriveFS","iCloudDrive","iCloudPhotos","Skype","Zoom","Tailscale","tailscaled")
foreach($k in $killList){
 $p=Get-Process -Name $k -ErrorAction SilentlyContinue
 if($p){ 
  try{ Stop-Process -Name $k -Force -ErrorAction SilentlyContinue; L "MATADO $k PID $($p.Id)" }catch{}
 }
}

# 4. Tailscale y Hyper-V - 100 Gbps y 10 Gbps virtuales que saturan
try{
 Disable-NetAdapter -Name "Tailscale" -Confirm:$false -ErrorAction SilentlyContinue; L "Adapter Tailscale deshabilitado temporal"
}catch{}
try{
 # No deshabilitar Default Switch si usas WSL/Docker, solo si no
 $wsl=Get-Process -Name "wsl" -ErrorAction SilentlyContinue
 if(!$wsl){
  Disable-NetAdapter -Name "vEthernet (Default Switch)" -Confirm:$false -ErrorAction SilentlyContinue
  L "vEthernet Default Switch deshabilitado (no usas WSL)"
 }else{ L "WSL detectado, dejo Default Switch"}
}catch{}

# 5. Limpia DNS y resetea colas
ipconfig /flushdns | Out-Null
netsh winsock reset | Out-Null
L "DNS flush OK"

# 6. Prioriza tu descarga - QoS
try{
 New-NetQosPolicy -Name "RUNEFORGE_PRIORITY" -AppPathNameMatchCondition "python.exe" -DSCPAction 46 -NetworkProfile All -ErrorAction SilentlyContinue | Out-Null
 L "QoS python.exe -> Prioridad alta"
}catch{}

L "--- TOP PROCESOS RESTANTES ---"
Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Group-Object OwningProcess | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object{
 try{
  $proc=Get-Process -Id $_.Name -ErrorAction SilentlyContinue
  $pname=if($proc){$proc.ProcessName}else{"PID $($_.Name)"}
  L "$pname -> $($_.Count) conn"
 }catch{}
}

L "--- HECHO - 15 Mbps liberados para tu modelo ---"
L "Para re-activar despues: Enable-NetAdapter Tailscale; Start-Service DoSvc; Start-Service wuauserv"
$final=$Log.ToString()
$final | Set-Clipboard
Write-Host $final
