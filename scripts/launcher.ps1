# runeforge_launcher.ps1 FIX v2 - corrige if -or
$ErrorActionPreference="SilentlyContinue"
Remove-Module PSReadLine -ErrorAction SilentlyContinue

$root = $PSScriptRoot
if(-not $root){ $root = (Get-Location).Path }
if($root -like "*\scripts"){ $root = Split-Path $root -Parent }
Set-Location $root

function Write-Status($msg,$color="White"){ Write-Host "[RUNEFORGE] $msg" -ForegroundColor $color }
function Test-Url($url){ try{ Invoke-RestMethod $url -TimeoutSec 3 | Out-Null; return $true }catch{ return $false } }

Write-Status "ROOT: $root" Cyan
Write-Status "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" DarkGray

Write-Status "Checking Ollama..." Yellow
try{
  $tags = Invoke-RestMethod http://127.0.0.1:11434/api/tags -TimeoutSec 3
  Write-Status "Ollama OK: $($tags.models.Count) modelos" Green
  ollama list
} catch { Write-Status "Ollama no responde en :11434" Red }

Write-Status "Node: $(node -v) NPM: $(npm -v)" DarkGray
if(Get-Command pm2 -ErrorAction SilentlyContinue){ pm2 list } else { Write-Status "pm2 no instalado" Red }

# FIX: parentesis correctos para -or
$hasServer = (Test-Path "src\backend\server.js")
$hasIndex = (Test-Path "src\backend\index.js")
if($hasServer -or $hasIndex){
  $entry = if($hasServer){ "src\backend\server.js" } else { "src\backend\index.js" }
  Write-Status "Levantando $entry" Yellow
  if(Test-Url "http://localhost:3100/api/ollama/status"){
    Write-Status "Backend ya en :3100" Green
  } else {
    if(Get-Command pm2 -ErrorAction SilentlyContinue){
      pm2 start $entry --name runeforge-backend --watch | Out-Null
    } else {
      Start-Process node -ArgumentList $entry -WindowStyle Minimized
    }
  }
} else {
  Write-Status "No hay backend Fastify aun (Etapa 1 solo LLM) - OK" DarkYellow
}

Write-Status "Endpoints: :3100/dashboard /forge /api/ollama/status y :11434" Cyan

try{
  node -e "const f=require('./src/backend/services/llm/factory.js'); f.createProvider('ollama').status().then(s=>console.log('FACTORY:', s.ok?'OK':'FAIL', 'count='+ (s.count||0)))"
} catch { Write-Status "Factory check fallo" Red }

Write-Status "Launcher OK. Usa 'pm2 logs' para logs" Cyan
