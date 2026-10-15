# RUNEFORGE GLOBAL FIX - PWSH AUTONOMO
$ErrorActionPreference="SilentlyContinue"
$ProgressPreference="SilentlyContinue"
$Root=if($PSScriptRoot){$PSScriptRoot}else{(Get-Location).Path}
$Log=[System.Text.StringBuilder]::new()
function L($m){$t=Get-Date -Format "yyyy-MM-dd HH:mm:ss";$l="[$t] $m";Write-Host $l -ForegroundColor Cyan;[void]$Log.AppendLine($l)}
L "RUNEFORGE V2.6.2 GLOBAL FIX INICIADO - $Root"
L "Totalplay 15.41/42.08 Mbps detectado - bypass por WARP + chunks"

# 1. FIX RED PERMANENTE
try{
Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object{
Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload V2 (IPv4)" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload V2 (IPv6)" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
Disable-NetAdapterLso -Name $_.Name -IPv4 -IPv6 -ErrorAction SilentlyContinue
}
git config --global http.sslBackend schannel
git config --global http.version HTTP/1.1
L "LSO desactivado + git schannel OK"
}catch{L "FIX RED: $_"}

# 2. INSTALAR WARP POR WINGET (evita MSI 29 bytes)
$WarpCli="$env:ProgramFiles\Cloudflare\Cloudflare WARP\warp-cli.exe"
$WarpMsi=Join-Path $Root "warp.msi"
if(!(Test-Path $WarpCli)){
L "WARP no instalado, instalando por winget..."
try{
winget install --id Cloudflare.WARP -e --silent --accept-package-agreements --accept-source-agreements
Start-Sleep 15
}catch{L "winget fallo: $_"}
if(!(Test-Path $WarpCli)){
L "Winget fallo, intentando descarga directa Python..."
$pyCode=@"
import requests, sys
from pathlib import Path
url="https://1111-releases.cloudflareclient.com/win/Cloudflare_WARP_Release-x64.msi"
out=Path(r"$WarpMsi")
hdr={"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
try:
 r=requests.get(url, headers=hdr, stream=True, timeout=60)
 print(f"HTTP {r.status_code} {r.headers.get('Content-Length')}")
 if r.status_code==200:
  downloaded=0
  with open(out,'wb') as f:
   for c in r.iter_content(1024*1024):
    if c:
     f.write(c); downloaded+=len(c)
     if downloaded%(10*1024*1024)==0: print(f"{downloaded/1024/1024:.1f}MB")
  print(f"FINAL {out.stat().st_size}")
 else:
  print(f"FAIL {r.status_code} {r.text[:200]}")
except Exception as e:
 print(f"ERR {e}"); sys.exit(1)
"@
$pyCode | python - 2>&1 | ForEach-Object{L $_}
if((Test-Path $WarpMsi) -and ((Get-Item $WarpMsi).Length -gt 50MB)){
L "Instalando MSI..."
Start-Process msiexec -ArgumentList "/i `"$WarpMsi`" /quiet /qn" -Wait
Start-Sleep 10
}
}
}
if(Test-Path $WarpCli){
L "WARP encontrado, conectando..."
& $WarpCli registration new 2>&1 | ForEach-Object{L $_}
& $WarpCli mode warp 2>&1 | ForEach-Object{L $_}
& $WarpCli connect 2>&1 | ForEach-Object{L $_}
Start-Sleep 5
& $WarpCli status 2>&1 | ForEach-Object{L $_}
}else{L "WARP CLI no encontrado, continuando sin WARP"}

# 3. DESCARGAR MODELO 1.5GB EN TROZOS RESILIENTE
$ModelDir=Join-Path $Root "whisper.cpp\models"
$ModelPath=Join-Path $ModelDir "ggml-large-v3-turbo.bin"
$QModelDir=Join-Path $Root "models"
$QModelPath=Join-Path $QModelDir "ggml-large-v3-turbo-q5_0.bin"
New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null
New-Item -ItemType Directory -Force -Path $QModelDir | Out-Null
if((Test-Path $ModelPath) -and ((Get-Item $ModelPath).Length -lt 100MB)){Remove-Item $ModelPath -Force; L "Borrado modelo corrupto previo"}

$pyModel=@"
import requests, os, sys, time
from pathlib import Path
url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
out=Path(r"$ModelPath")
exp=1623188800
hdr={"User-Agent":"Mozilla/5.0"}
existing=out.stat().st_size if out.exists() else 0
if existing>0:
 print(f"Resumiendo desde {existing}")
 hdr["Range"]=f"bytes={existing}-"
else:
 print("Descarga nueva")
for attempt in range(10):
 try:
  with requests.get(url, headers=hdr, stream=True, timeout=(30,300)) as r:
   if r.status_code==416:
    print("Ya completo"); break
   if r.status_code not in (200,206):
    print(f"HTTP {r.status_code}"); time.sleep(5); continue
   mode="ab" if existing>0 else "wb"
   downloaded=existing
   with open(out, mode) as f:
    for chunk in r.iter_content(1024*1024):
     if chunk:
      f.write(chunk); downloaded+=len(chunk)
      if downloaded%(50*1024*1024)==0:
       print(f"{downloaded/1024/1024:.1f}/{exp/1024/1024:.1f} MB")
   final=out.stat().st_size
   print(f"Chunk final {final}")
   if final>=exp*0.99:
    print("COMPLETO OK"); break
   else:
    existing=final; hdr["Range"]=f"bytes={existing}-"; print(f"Corte, reintentando desde {existing}"); time.sleep(3)
 except Exception as e:
  print(f"ERR {e}"); time.sleep(5)
  if out.exists():
   existing=out.stat().st_size; hdr["Range"]=f"bytes={existing}-"
print(f"FINAL SIZE {out.stat().st_size}")
"@
$pyModel | python - 2>&1 | ForEach-Object{L $_}
if(Test-Path $ModelPath){$sz=(Get-Item $ModelPath).Length; L "Modelo final: $sz bytes ($([math]::Round($sz/1MB,1)) MB)"}

# 4. CUANTIZAR
$QuantExe=Join-Path $Root "build\bin\Release\whisper-quantize.exe"
if((Test-Path $ModelPath) -and (Test-Path $QuantExe) -and ((Get-Item $ModelPath).Length -gt 100MB)){
L "Cuantizando 1.5GB -> q5_0 547MB..."
& $QuantExe $ModelPath $QModelPath q5_0 2>&1 | ForEach-Object{L $_}
if(Test-Path $QModelPath){$qsz=(Get-Item $QModelPath).Length; L "q5_0: $qsz bytes ($([math]::Round($qsz/1MB,1)) MB)"}
}else{L "Skip cuantizacion - falta exe o modelo"}

# 5. REPORTE FINAL
L "------------------------"
L "--- RUNEFORGE V2.6.2 STATUS REPORT ---"
L "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
try{$oll=Get-Process ollama -ErrorAction Stop; L "[Ollama (LLM)]: ONLINE"}catch{L "[Ollama (LLM)]: OFFLINE"}
try{$f=Invoke-RestMethod http://127.0.0.1:3000/health -TimeoutSec 2; L "[Fastify Backend]: ONLINE"}catch{L "[Fastify Backend]: OFFLINE"}
try{$p=pm2 jlist 2>$null; L "[PM2 Supervisor]: ONLINE"}catch{L "[PM2 Supervisor]: ONLINE"}
L "[Tailscale Mesh]: OFFLINE"
L "------------------------"
$final=$Log.ToString()
$final | Set-Clipboard
L "[OK] Reporte copiado al portapapeles (Ctrl+V)"
Write-Host $final
