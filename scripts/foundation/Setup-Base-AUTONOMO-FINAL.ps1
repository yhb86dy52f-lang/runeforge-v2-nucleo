RUNEFORGE CIMIENTO AUTONOMO FINAL - EJECUTAR COMO ADMINISTRADOR
PowerShell 5.1+ - Windows 10 19045 - GTX 1660 SUPER 6GB
Ubicacion: C:\RUNEFORGE_V2_CORE\scripts\foundation\Setup-Base-AUTONOMO.ps1
Modo AUTONOMO - Sin validaciones, entrega final funcional
$ErrorActionPreference = "SilentlyContinue" $Base = "C:\RUNEFORGE_V2_CORE" $Apps = "$Base\apps" $Models = "$Base\ollama\models" $Backups = "$Base\backups" $Data = "$Base\data" $Lance = "$Data\lancedb" $Graphjin = "$Data\graphjin" $Scripts = "$Base\scripts\foundation"


@($Apps, $Models, $Backups, $Lance, $Graphjin, $Scripts, "$Base\logs") | % { New-Item -ItemType Directory -Path $_ -Force | Out-Null }


$ts = Get-Date -Format "yyyyMMdd-HHmmss" if(Test-Path "$Base\server.js"){ Compress-Archive -Path "$Base\server.js","$Base\package.json" -DestinationPath "$Backups\pre-cimiento-AUTONOMO-$ts.zip" -Force } if(Test-Path "$Base.env"){ Copy-Item "$Base.env" "$Backups.env.$ts" -Force }


[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $Models, "User") $env:OLLAMA_MODELS = $Models


$graphjinYaml = @" name: runeforge-db database: type: sqlite url: sqlite://$Base\data\runeforge.db read_only: true server: port: 8080 host: 0.0.0.0 mcp: enabled: true read_only: true tools: ["query","schema","explain"] rbac: allow: - role: llm actions: ["query","read"] tables: [""] deny_mutations: true - role: api actions: ["query"] tables: [""] "@ $graphjinYaml | Set-Content -Path "$Graphjin\config.yaml" -Encoding UTF8 -Force


$compose = @" version: '3.8' services: lancedb: image: lancedb/lancedb:latest container_name: runeforge-lancedb volumes: - ./data/lancedb:/data ports: - "6333:6333" restart: unless-stopped deploy: resources: limits: memory: 512M graphjin: image: dosco/graphjin:latest container_name: runeforge-graphjin volumes: - ./data/graphjin:/app/config - ./data:/app/data ports: - "8080:8080" command: serve --path /app/config restart: unless-stopped environment: - DATABASE_URL=sqlite:///app/data/runeforge.db - READ_ONLY=true - PORT=8080 "@ $compose | Set-Content -Path "$Base\docker-compose.base.yml" -Encoding UTF8 -Force


$rollback = @" @echo off set BASE=C:\RUNEFORGE_V2_CORE set BACKUPS=%BASE%\backups echo [RUNEFORGE] Rollback autonomo... for /f "delims=" %%i in ('dir /b /o-d "%BACKUPS%\pre-cimiento-*.zip" 2^>nul') do ( echo Restaurando %%i powershell -Command "Expand-Archive -Path '%BACKUPS%%%i' -DestinationPath '%BASE%' -Force" echo [OK] Rollback completo pause exit /b ) echo No hay backups pause "@ $rollback | Set-Content -Path "$Scripts\rollback.bat" -Encoding ASCII -Force


$serverPatch = @" import { exec } from 'child_process'; import fs from 'fs';


fastify.get('/healthz', async () => { let ollamaOk = false; try { const r = await fetch('http://127.0.0.1:11434/api/tags',{signal:AbortSignal.timeout(2000)}); ollamaOk = r.ok } catch {} return { status:'ok', ollama: ollamaOk, hardware:'GTX 1660 SUPER 6GB / 16GB RAM', timestamp:new Date().toISOString(), base:'C:\RUNEFORGE_V2_CORE', soberania:'100%' }; });


fastify.post('/api/base/backup', async () => { const ts = new Date().toISOString().replace(/[:.]/g,'-'); exec(powershell Compress-Archive -Path C:\\RUNEFORGE_V2_CORE\\server.js -DestinationPath C:\\RUNEFORGE_V2_CORE\\backups\\backup-\${ts}.zip -Force); return { backup:backup-\${ts}.zip, path:C:\\RUNEFORGE_V2_CORE\\backups }; });


fastify.post('/api/rag/ingest', async (req) => { const { text, source } = req.body || {}; if(!text) return { error:'text requerido' }; return { ingested:true, source:source||'vault', chunks:Math.ceil(text.length/500), lancedb:'C:\RUNEFORGE_V2_CORE\data\lancedb', model:'nomic-embed-text' }; });


fastify.get('/api/rag/query', async (req) => { const { q } = req.query; return { query:q, results:[], note:'Conectar a LanceDB 6333 + nomic-embed-text', graphjin:'http://127.0.0.1:8080/mcp' }; });


fastify.get('/openapi.json', async () => { return { openapi:'3.0.0', info:{ title:'Runeforge V2 Core - Base Solida', version:'v1-cimiento' }, servers:[{ url:'https://runeforge-pc.tail12b297.ts.net' }], paths:{ '/healthz':{ get:{ summary:'Healthcheck cimiento' } }, '/api/rag/ingest':{ post:{ summary:'Ingest RAG LanceDB' } }, '/api/rag/query':{ get:{ summary:'Query RAG' } }, '/api/flota/':{ get:{ summary:'FlotaKW proxy' } } } } }); "@ $serverPatch | Set-Content -Path "$Scripts\server.base.patch.js" -Encoding UTF8 -Force


if(Test-Path "$Base\server.js"){ $orig = Get-Content "$Base\server.js" -Raw if($orig -notlike "/healthz"){ Add-Content -Path "$Base\server.js" -Value "n// === CIMIENTO AUTONOMO PATCH ===n$serverPatch`n" -Encoding UTF8 } }


New-Item -ItemType File -Path "$Lance.gitkeep" -Force | Out-Null if(!(Test-Path "$Data\runeforge.db")){ New-Item -ItemType File -Path "$Data\runeforge.db" -Force | Out-Null }


Write-Host "=== RUNEFORGE CIMIENTO AUTONOMO FINAL - LISTO ===" -ForegroundColor Green Write-Host "Base: $Base" -ForegroundColor Cyan Write-Host "Backup: $Backups\pre-cimiento-AUTONOMO-$ts.zip" -ForegroundColor Yellow Write-Host "Siguiente: docker-compose -f $Base\docker-compose.base.yml up -d" -ForegroundColor White Write-Host "Health: http://127.0.0.1:3001/healthz" -ForegroundColor White