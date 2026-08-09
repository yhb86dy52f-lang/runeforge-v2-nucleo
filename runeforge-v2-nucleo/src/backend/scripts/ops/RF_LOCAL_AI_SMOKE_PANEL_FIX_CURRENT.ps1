$ErrorActionPreference="Stop"
$Fecha=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Stamp=Get-Date -Format "yyyyMMdd_HHmmss"
Write-Host "[RF_LOCAL_AI_SMOKE_PANEL_FIX_CURRENT][$Fecha]" -ForegroundColor Cyan
[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)
$Base="C:\RUNEFOGE_PRO"
$Root=Join-Path $Base "runeforge"
$App=Join-Path $Root "app"
$AppJs=Join-Path $App "src\app.js"
$ServerJs=Join-Path $App "src\server.js"
$LocalAiDir=Join-Path $App "src\modules\local_ai"
$RoutesFile=Join-Path $LocalAiDir "local_ai.routes.js"
$PanelDir=Join-Path $App "public\forge"
$PanelFile=Join-Path $PanelDir "local-ai.html"
$ReportDir=Join-Path $Root "data\reports\local_ai"
$TraceDir=Join-Path $Root "data\traces"
$BackupDir=Join-Path $Root "data\backups\current_overwrite\local_ai_smoke_panel_fix\$Stamp"
$Report=Join-Path $ReportDir "RF_LOCAL_AI_SMOKE_PANEL_FIX_CURRENT.md"
$Json=Join-Path $TraceDir "rf_local_ai_smoke_panel_fix_current.json"
New-Item -ItemType Directory -Force -Path $LocalAiDir,$PanelDir,$ReportDir,$TraceDir,$BackupDir | Out-Null
foreach($F in @($Report,$Json,$AppJs,$RoutesFile,$PanelFile)){if(Test-Path -LiteralPath $F){Copy-Item -LiteralPath $F -Destination (Join-Path $BackupDir ((Split-Path $F -Leaf)+".bak")) -Force}}
if(!(Test-Path -LiteralPath $AppJs)){throw "NO_EXISTE_APP_JS: $AppJs"}
if(!(Test-Path -LiteralPath $ServerJs)){throw "NO_EXISTE_SERVER_JS: $ServerJs"}
$Routes=@("const express = require('express');","const localAi = require('./local_ai.service');","","const router = express.Router();","","router.use(express.json({ limit: '32kb' }));","","router.get('/health', async (_req, res) => {","  try {","    const result = await localAi.health();","    res.status(result.service ? 200 : 503).json(result);","  } catch (error) {","    res.status(503).json({ ok:false, service:'Runeforge Local AI', error:error.message, ts:new Date().toISOString() });","  }","});","","router.get('/smoke', async (_req, res) => {","  try {","    const result = await localAi.chat({ message:'Responde solo OK', model:'qwen2.5:1.5b', num_predict:8, temperature:0 });","    res.status(result.ok ? 200 : 500).json(result);","  } catch (error) {","    res.status(500).json({ ok:false, status:'ERROR', error:error.message, ts:new Date().toISOString() });","  }","});","","router.post('/chat', async (req, res) => {","  try {","    const result = await localAi.chat(req.body || {});","    res.status(result.ok ? 200 : 500).json(result);","  } catch (error) {","    res.status(500).json({ ok:false, status:'ERROR', error:error.message, ts:new Date().toISOString() });","  }","});","","module.exports = router;")
$Routes | Set-Content -LiteralPath $RoutesFile -Encoding UTF8 -Force
$Html=@("<!doctype html>","<html lang='es'>","<head>","<meta charset='utf-8'>","<meta name='viewport' content='width=device-width,initial-scale=1'>","<title>Runeforge Local AI</title>","<style>body{margin:0;background:#0d0211;color:#f3eaff;font-family:system-ui,Segoe UI,Arial,sans-serif}main{max-width:960px;margin:auto;padding:24px}.card{background:#16051f;border:1px solid #372146;border-radius:18px;padding:18px;margin-bottom:14px;box-shadow:0 0 24px rgba(188,0,255,.12)}textarea{width:100%;min-height:130px;background:#09010d;color:#f3eaff;border:1px solid #372146;border-radius:12px;padding:12px;box-sizing:border-box}button{background:#7c3aed;color:white;border:0;border-radius:10px;padding:10px 14px;margin:8px 6px 0 0;font-weight:700;cursor:pointer}pre{background:#070009;border:1px solid #372146;border-radius:12px;padding:14px;white-space:pre-wrap}.muted{color:#a990bd}</style>","</head>","<body>","<main>","<section class='card'><h1>Runeforge Local AI</h1><div class='muted'>Ollama local · qwen2.5:1.5b · shell bloqueado · trace JSONL</div></section>","<section class='card'><textarea id='prompt' placeholder='Escribe una consulta para Runeforge...'></textarea><br><button onclick='chat()'>Enviar</button><button onclick='health()'>Health</button><button onclick='smoke()'>Smoke</button></section>","<section class='card'><pre id='out'>Listo.</pre></section>","</main>","<script>const out=document.getElementById('out');async function health(){out.textContent='Validando health...';const r=await fetch('/api/ai/local/health');out.textContent=JSON.stringify(await r.json(),null,2)}async function smoke(){out.textContent='Validando smoke...';const r=await fetch('/api/ai/local/smoke');out.textContent=JSON.stringify(await r.json(),null,2)}async function chat(){const message=document.getElementById('prompt').value.trim();out.textContent='Procesando...';const r=await fetch('/api/ai/local/chat',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({message,num_predict:160,temperature:0.2})});const j=await r.json();out.textContent=j.content||JSON.stringify(j,null,2)}</script>","</body>","</html>")
$Html | Set-Content -LiteralPath $PanelFile -Encoding UTF8 -Force
$AppText=Get-Content -LiteralPath $AppJs -Raw -Encoding UTF8
$Begin="// === RF_LOCAL_AI_FINAL_CURRENT_BEGIN ==="
$End="// === RF_LOCAL_AI_FINAL_CURRENT_END ==="
$PanelPathJs=$PanelFile.Replace("\","\\")
$Patch=@($Begin,"const rfLocalAiRoutesCurrent = require('./modules/local_ai/local_ai.routes');","app.use('/api/ai/local', rfLocalAiRoutesCurrent);","app.get('/forge/local-ai.html', function(_req, res) {","  res.sendFile('"+$PanelPathJs+"');","});",$End) -join [Environment]::NewLine
$Pattern="(?s)"+[regex]::Escape($Begin)+".*?"+[regex]::Escape($End)
if([regex]::IsMatch($AppText,$Pattern)){$AppText=[regex]::Replace($AppText,$Pattern,[System.Text.RegularExpressions.MatchEvaluator]{param($m)$Patch},1)}elseif($AppText -notmatch "rfLocalAiRoutesCurrent"){$Regex="(?m)^(\s*(?:const|let|var)\s+app\s*=\s*express\s*\(\s*\)\s*;.*)$"; if([regex]::IsMatch($AppText,$Regex)){$AppText=[regex]::Replace($AppText,$Regex,[System.Text.RegularExpressions.MatchEvaluator]{param($m)$m.Value+[Environment]::NewLine+$Patch},1)}else{$AppText=$AppText.TrimEnd()+[Environment]::NewLine+$Patch+[Environment]::NewLine}}
[System.IO.File]::WriteAllText($AppJs,$AppText,[System.Text.UTF8Encoding]::new($false))
foreach($F in @($RoutesFile,$AppJs)){& node --check $F | Out-Null; if($LASTEXITCODE -ne 0){throw "NODE_CHECK_FAILED: $F"}}
$Pm2Action="NO_PM2"
$Pm2Cmd=Get-Command pm2 -ErrorAction SilentlyContinue
if($Pm2Cmd){$Raw=(& pm2 jlist 2>$null) -join "`n"; $List=@(); if($Raw.Trim()){try{$List=$Raw | ConvertFrom-Json -Depth 80}catch{}}; $Target=@($List | Where-Object {($_.name -match "runeforge") -or ($_.pm2_env.cwd -eq $App) -or ($_.pm2_env.pm_exec_path -like "*runeforge*")}) | Select-Object -First 1; if($Target){& pm2 restart $Target.pm_id --update-env | Out-Null; $Pm2Action="RESTARTED_PM2_ID_$($Target.pm_id)"}else{Push-Location $App; & pm2 start $ServerJs --name "runeforge-mvp" --update-env | Out-Null; Pop-Location; $Pm2Action="STARTED_RUNEFORGE_MVP"}}
$BaseUrl="http://127.0.0.1:3100"
Start-Sleep -Seconds 4
$BackendOk=$false; $HealthOk=$false; $SmokeOk=$false; $ChatOk=$false; $PanelOk=$false
try{$B=Invoke-RestMethod "$BaseUrl/health" -TimeoutSec 8; $BackendOk=($B.ok -eq $true)}catch{}
try{$H=Invoke-RestMethod "$BaseUrl/api/ai/local/health" -TimeoutSec 8; $HealthOk=($H.service -eq "Runeforge Local AI")}catch{}
try{$S=Invoke-RestMethod "$BaseUrl/api/ai/local/smoke" -TimeoutSec 180; $SmokeOk=($S.ok -eq $true -and [string]$S.content)}catch{}
try{$Body=@{message="Responde solo OK";model="qwen2.5:1.5b";num_predict=8;temperature=0} | ConvertTo-Json -Depth 8; $C=Invoke-RestMethod "$BaseUrl/api/ai/local/chat" -Method Post -ContentType "application/json" -Body $Body -TimeoutSec 180; $ChatOk=($C.ok -eq $true -and [string]$C.content)}catch{}
try{$P=Invoke-WebRequest "$BaseUrl/forge/local-ai.html" -TimeoutSec 10; $PanelOk=($P.StatusCode -eq 200 -and $P.Content.Length -gt 500)}catch{}
$Residual=@(); if(!$BackendOk){$Residual+="BACKEND_FAIL"}; if(!$HealthOk){$Residual+="LOCAL_AI_HEALTH_FAIL"}; if(!$SmokeOk){$Residual+="LOCAL_AI_SMOKE_FAIL"}; if(!$ChatOk){$Residual+="LOCAL_AI_CHAT_FAIL"}; if(!$PanelOk){$Residual+="LOCAL_AI_PANEL_FAIL"}
$Status=if($Residual.Count -eq 0){"LOCAL_AI_SMOKE_PANEL_FIX_OK"}else{"LOCAL_AI_SMOKE_PANEL_FIX_PARTIAL"}
$Next=if($Status -eq "LOCAL_AI_SMOKE_PANEL_FIX_OK"){"RF_DEV_QUALITY_GATE_CURRENT"}else{"RF_LOCAL_AI_DEEP_DIAG_CURRENT"}
$Summary=[pscustomobject]@{timestamp=(Get-Date).ToString("o");phase="RF_LOCAL_AI_SMOKE_PANEL_FIX_CURRENT";status=$Status;backend_ok=$BackendOk;local_ai_health_ok=$HealthOk;local_ai_smoke_ok=$SmokeOk;local_ai_chat_ok=$ChatOk;panel_ok=$PanelOk;pm2_action=$Pm2Action;panel_url="$BaseUrl/forge/local-ai.html";residual=$Residual;backup_dir=$BackupDir;next=$Next;backend="TOCADO_LOCAL_AI_ROUTE_ONLY";n8n="NO_TOCADO";drive_d="NO_TOCADO"}
@("# RF_LOCAL_AI_SMOKE_PANEL_FIX_CURRENT","","Fecha: $Fecha","","Estado: $Status","Backend OK: $BackendOk","Health OK: $HealthOk","Smoke OK: $SmokeOk","Chat OK: $ChatOk","Panel OK: $PanelOk","PM2: $Pm2Action","","Panel: $BaseUrl/forge/local-ai.html","","Residual:",(($Residual | ForEach-Object {"- $_"}) -join [Environment]::NewLine),"","Backup: $BackupDir","n8n: NO_TOCADO","D: NO_TOCADO","","Siguiente: $Next") | Set-Content -LiteralPath $Report -Encoding UTF8 -Force
$Summary | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Json -Encoding UTF8 -Force
[pscustomobject]@{Estado=$Status; BackendOk=$BackendOk; LocalAiHealthOk=$HealthOk; LocalAiSmokeOk=$SmokeOk; LocalAiChatOk=$ChatOk; PanelOk=$PanelOk; PanelUrl="$BaseUrl/forge/local-ai.html"; Residual=($Residual -join ", "); Report=$Report; Json=$Json; Next=$Next; Backend="TOCADO_LOCAL_AI_ROUTE_ONLY"; N8n="NO_TOCADO"; DriveD="NO_TOCADO"} | Format-List
if($PanelOk){Start-Process "$BaseUrl/forge/local-ai.html"}
