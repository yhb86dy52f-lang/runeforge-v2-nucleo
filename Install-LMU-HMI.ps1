# =====================================================================
# RUNEFORGE :: LMU-2630 HMI :: BOOTSTRAP v8
# Fix definitivo: OpenSSL legacy + limpieza agresiva + fallback HTTP registry
# Ejecutar desde: C:\RUNEFORGE_V2_CORE
#   powershell -ExecutionPolicy Bypass -File .\Install-LMU-HMI.ps1
# =====================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =====================================================================
# FIX CRÍTICO #1: OpenSSL legacy provider desde el inicio
# Esto resuelve ERR_SSL_CIPHER_OPERATION_FAILED / ossl_gcm_stream_update
# =====================================================================
$env:NODE_OPTIONS = "--openssl-legacy-provider --max-old-space-size=4096"
$env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
$env:OPENSSL_CONF = ""
$env:OPENSSL_MODULES = ""

$APP_NAME = "lmu-hmi-desktop"
$APP_ROOT = "C:\RUNEFORGE_V2_CORE\apps\$APP_NAME"
$NODE_VER = "20.18.0"
$NODE_DIR = "$APP_ROOT\.node20"
$NODE_ZIP = "$env:TEMP\node-v$NODE_VER-win-x64.zip"

function Test-Cmd($n) { return [bool](Get-Command $n -ErrorAction SilentlyContinue) }

# =====================================================================
# FIX CRÍTICO #2: Limpieza agresiva de procesos y archivos bloqueados
# =====================================================================
function Invoke-FullCleanup {
    Write-Host "[*] Matando procesos Node/npm/npx residuales..." -ForegroundColor Yellow
    Get-Process -Name "node","npm","npx","esbuild","vite" -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    if (Test-Path "$APP_ROOT\node_modules") {
        Write-Host "[*] Liberando handles en node_modules (takeown+attrib)..." -ForegroundColor Yellow
        & cmd /c "takeown /F `"$APP_ROOT\node_modules`" /R /D Y >nul 2>&1"
        & cmd /c "attrib -R -H -S `"$APP_ROOT\node_modules\*.*`" /S /D >nul 2>&1"
        Write-Host "[*] Borrando node_modules con rmdir nativo..." -ForegroundColor Yellow
        & cmd /c "rmdir /s /q `"$APP_ROOT\node_modules`" >nul 2>&1"
        Start-Sleep -Seconds 1
        if (Test-Path "$APP_ROOT\node_modules") {
            Remove-Item "$APP_ROOT\node_modules" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Remove-Item "$APP_ROOT\package-lock.json" -Force -ErrorAction SilentlyContinue
    Remove-Item "$APP_ROOT\yarn.lock" -Force -ErrorAction SilentlyContinue
}

# ---------- Descarga robusta ----------
function Get-FileRobust {
    param([string]$Url, [string]$OutFile, [string[]]$Mirrors = @(), [long]$MinSize = 1024)
    if (Test-Path $OutFile) {
        $len = (Get-Item $OutFile).Length
        if ($len -ge $MinSize) { Write-Host "    [cache] $([System.IO.Path]::GetFileName($OutFile)) ($([math]::Round($len/1MB,1)) MB)" -ForegroundColor DarkGray; return }
        Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
    }
    $candidates = @($Url) + $Mirrors
    foreach ($u in $candidates) {
        if (Test-Cmd "curl.exe") {
            try {
                Write-Host "    [curl] $u" -ForegroundColor DarkGray
                & curl.exe -L --fail --silent --show-error --retry 3 --retry-delay 2 `
                           --connect-timeout 30 --max-time 900 -o $OutFile $u
                if ($LASTEXITCODE -eq 0 -and (Test-Path $OutFile) -and (Get-Item $OutFile).Length -ge $MinSize) { return }
            } catch {}
            Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
        }
        try {
            Write-Host "    [bits] $u" -ForegroundColor DarkGray
            Start-BitsTransfer -Source $u -Destination $OutFile -ErrorAction Stop
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -ge $MinSize) { return }
        } catch {}
        Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
        try {
            Write-Host "    [iwr]  $u" -ForegroundColor DarkGray
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $u -OutFile $OutFile -UseBasicParsing -TimeoutSec 600
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).Length -ge $MinSize) { return }
        } catch { Write-Host "    [!] $($_.Exception.Message)" -ForegroundColor DarkYellow }
        Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
    }
    throw "No se pudo descargar $Url"
}

function Test-ZipValid {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $false }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $count = $zip.Entries.Count
        $zip.Dispose()
        return ($count -gt 0)
    } catch { return $false }
}

function Expand-ZipRobust {
    param([string]$ZipPath, [string]$DestDir)
    if (Test-Path $DestDir) { Remove-Item $DestDir -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    if (Test-Cmd "tar.exe") {
        try {
            Write-Host "    [tar] extrayendo..." -ForegroundColor DarkGray
            & tar.exe -xf $ZipPath -C $DestDir
            if ($LASTEXITCODE -eq 0 -and (Get-ChildItem $DestDir -Recurse -ErrorAction SilentlyContinue).Count -gt 0) { return $true }
        } catch {}
    }
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $DestDir)
        if ((Get-ChildItem $DestDir -Recurse -ErrorAction SilentlyContinue).Count -gt 0) { return $true }
    } catch {}
    try { Expand-Archive -Path $ZipPath -DestinationPath $DestDir -Force; return $true } catch {}
    return $false
}

Write-Host "`n[RUNEFORGE] Bootstrap v8 LMU-HMI Desktop`n" -ForegroundColor Cyan

# ---------- 0. Limpieza total ----------
Invoke-FullCleanup

$keepNode = Test-Path "$NODE_DIR\node.exe"
if (Test-Path $APP_ROOT) {
    Write-Host "[*] Limpiando directorio de app..." -ForegroundColor Yellow
    if ($keepNode) {
        $tmpNode = "$env:TEMP\lmu-node20-keep"
        Remove-Item $tmpNode -Recurse -Force -ErrorAction SilentlyContinue
        Move-Item $NODE_DIR $tmpNode -Force
        Remove-Item $APP_ROOT -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $APP_ROOT -Force | Out-Null
        Move-Item $tmpNode $NODE_DIR -Force
    } else {
        Remove-Item $APP_ROOT -Recurse -Force -ErrorAction SilentlyContinue
    }
}
New-Item -ItemType Directory -Path $APP_ROOT -Force | Out-Null
Set-Location $APP_ROOT

# ---------- 1. Node 20 portable ----------
if (-not (Test-Path "$NODE_DIR\node.exe")) {
    Write-Host "[*] Node 20 portable..." -ForegroundColor Yellow
    if (Test-Path $NODE_ZIP) {
        if (-not (Test-ZipValid $NODE_ZIP)) { Remove-Item $NODE_ZIP -Force }
    }
    Get-FileRobust -Url "https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-win-x64.zip" `
        -OutFile $NODE_ZIP -MinSize 20MB `
        -Mirrors @("https://npmmirror.com/mirrors/node/v$NODE_VER/node-v$NODE_VER-win-x64.zip")
    if (-not (Test-ZipValid $NODE_ZIP)) {
        Remove-Item $NODE_ZIP -Force
        Get-FileRobust -Url "https://nodejs.org/dist/v$NODE_VER/node-v$NODE_VER-win-x64.zip" -OutFile $NODE_ZIP -MinSize 20MB
        if (-not (Test-ZipValid $NODE_ZIP)) { Write-Host "[X] ZIP irrecuperable." -ForegroundColor Red; exit 1 }
    }
    Write-Host "    Extrayendo Node..." -ForegroundColor DarkGray
    $tmpExtract = "$APP_ROOT\.node-extract"
    if (-not (Expand-ZipRobust -ZipPath $NODE_ZIP -DestDir $tmpExtract)) { Write-Host "[X] Falló extracción de Node." -ForegroundColor Red; exit 1 }
    $innerDir = Get-ChildItem $tmpExtract -Directory | Select-Object -First 1
    if (-not $innerDir) { Write-Host "[X] ZIP sin carpeta raíz." -ForegroundColor Red; exit 1 }
    Move-Item $innerDir.FullName $NODE_DIR
    Remove-Item $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue
}
if (-not (Test-Path "$NODE_DIR\node.exe")) { Write-Host "[X] node.exe no encontrado." -ForegroundColor Red; exit 1 }
$env:Path = "$NODE_DIR;$env:Path"
Write-Host "[OK] Node activo: $(node -v) (portable)" -ForegroundColor Green
$npm = "$NODE_DIR\npm.cmd"

# ---------- 2. Rust ----------
$rustBin = "$env:USERPROFILE\.cargo\bin"
if ($env:Path -notlike "*$rustBin*") { $env:Path = "$rustBin;$env:Path" }
if (-not (Test-Cmd "cargo")) {
    Write-Host "[*] Instalando Rust..." -ForegroundColor Yellow
    $rustup = "$env:TEMP\rustup-init.exe"
    Get-FileRobust -Url "https://win.rustup.rs/x86_64" -OutFile $rustup -MinSize 1MB
    & $rustup -y --default-toolchain stable --profile minimal --no-modify-path
    $env:Path = "$rustBin;$env:Path"
}
if (-not (Test-Cmd "cargo")) { Write-Host "[X] Rust no disponible." -ForegroundColor Red; exit 1 }
Write-Host "[OK] Rust: $(rustc --version)" -ForegroundColor Green

# =====================================================================
# FIX CRÍTICO #3: Limpiar caché npm global (crítico - cache corrupta)
# =====================================================================
Write-Host "[*] Limpiando caché de npm..." -ForegroundColor Yellow
& $npm cache clean --force 2>&1 | Out-Null
& $npm cache verify 2>&1 | Out-Null

# ---------- 3. Config npm con OpenSSL legacy ----------
Write-Host "[*] Configurando npm (OpenSSL legacy + TLS relajado)..." -ForegroundColor Yellow
& $npm config set strict-ssl false --location=user 2>&1 | Out-Null
& $npm config set fetch-retries 5 --location=user 2>&1 | Out-Null
& $npm config set fetch-retry-maxtimeout 120000 --location=user 2>&1 | Out-Null
& $npm config set fetch-timeout 300000 --location=user 2>&1 | Out-Null

@"
strict-ssl=false
fetch-retries=5
fetch-timeout=300000
audit=false
fund=false
registry=https://registry.npmjs.org/
"@ | Set-Content ".npmrc" -Encoding ASCII

# ---------- 4. Scaffold manual ----------
Write-Host "[1/6] Scaffold manual..." -ForegroundColor DarkCyan

@'
{
  "name": "lmu-hmi-desktop",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "tauri": "tauri",
    "desktop": "tauri dev",
    "desktop:build": "tauri build"
  }
}
'@ | Set-Content "package.json" -Encoding UTF8

@'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020","DOM","DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": false,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
'@ | Set-Content "tsconfig.json" -Encoding UTF8

@'
<!doctype html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no" />
    <title>LMU-2630 HMI</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'@ | Set-Content "index.html" -Encoding UTF8

@'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: { port: 5173, strictPort: true, host: '127.0.0.1' },
  envPrefix: ['VITE_','TAURI_'],
  build: { target: 'es2021', minify: 'esbuild', sourcemap: false }
})
'@ | Set-Content "vite.config.ts" -Encoding UTF8

@'
/** @type {import('tailwindcss').Config} */
export default { content: ["./index.html","./src/**/*.{js,ts,jsx,tsx}"], theme: { extend: {} }, plugins: [] }
'@ | Set-Content "tailwind.config.js" -Encoding UTF8

@'
export default { plugins: { tailwindcss: {}, autoprefixer: {} } }
'@ | Set-Content "postcss.config.js" -Encoding UTF8

New-Item -ItemType Directory -Path "src" -Force | Out-Null

@'
@tailwind base;
@tailwind components;
@tailwind utilities;
html,body,#root{height:100%;margin:0;padding:0}
body{background:#020617;overscroll-behavior:none;-webkit-user-select:none;user-select:none}
*{-webkit-tap-highlight-color:transparent}
'@ | Set-Content "src\index.css" -Encoding UTF8

@'
/// <reference types="vite/client" />
'@ | Set-Content "src\vite-env.d.ts" -Encoding UTF8

@'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'
ReactDOM.createRoot(document.getElementById('root')!).render(<React.StrictMode><App/></React.StrictMode>)
'@ | Set-Content "src\main.tsx" -Encoding UTF8

$appTsx = @'
import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Activity, Cpu, RotateCcw, Layers, Plus, Trash2, Send,
  Sparkles, FolderOpen, Save, FileText, RefreshCw, Download, Upload
} from 'lucide-react';
import { writeTextFile, readTextFile, readDir, remove, mkdir, exists } from '@tauri-apps/plugin-fs';
import { open, save } from '@tauri-apps/plugin-dialog';
import { appDataDir, join } from '@tauri-apps/api/path';

const LMU_PINS = [
  { id:"PWR",label:"PWR 12V" },{ id:"GND",label:"GND" },
  { id:"OUT0",label:"OUT0" },{ id:"OUT1",label:"OUT1" },{ id:"OUT2",label:"OUT2" }
];
const COMP_PINS:any = {
  relay: [{id:"85"},{id:"86"},{id:"30"},{id:"87a"},{id:"87"}],
  lamp:  [{id:"A"},{id:"B"}]
};
const COMP_SIZES:any = { lmu:{w:260,h:130}, relay:{w:110,h:78}, lamp:{w:72,h:72} };
const PIN_OFFSETS:any = {
  lmu:{ PWR:{x:12,y:12}, GND:{x:12,y:92}, OUT0:{x:228,y:10}, OUT1:{x:228,y:48}, OUT2:{x:228,y:86} },
  relay:{ "85":{x:12,y:-22},"86":{x:78,y:-22},"30":{x:6,y:68},"87a":{x:45,y:68},"87":{x:84,y:68} },
  lamp:{ A:{x:26,y:-22}, B:{x:26,y:72} }
};

class DisjointSet {
  parent:Map<string,string>; rank:Map<string,number>;
  constructor(elements:string[]){ this.parent=new Map(); this.rank=new Map();
    elements.forEach(el=>{ this.parent.set(el,el); this.rank.set(el,0); }); }
  find(i:string):string { let r=this.parent.get(i)!; if(r!==i){ r=this.find(r); this.parent.set(i,r);} return r; }
  union(i:string,j:string):boolean {
    const ri=this.find(i), rj=this.find(j); if(ri===rj) return false;
    const a=this.rank.get(ri)!, b=this.rank.get(rj)!;
    if(a<b) this.parent.set(ri,rj); else if(a>b) this.parent.set(rj,ri);
    else { this.parent.set(rj,ri); this.rank.set(ri,a+1); } return true;
  }
}

function getDefaultCircuit(){
  return {
    comps: [
      { id:"LMU", type:"lmu", x:24, y:40 },
      { id:"R1", type:"relay", x:340, y:120 },
      { id:"L1", type:"lamp", x:500, y:160 }
    ],
    wires: [
      { id:"W1", a:{cId:"LMU",pinId:"OUT0"}, b:{cId:"R1",pinId:"85"} },
      { id:"W2", a:{cId:"R1",pinId:"86"}, b:{cId:"LMU",pinId:"GND"} },
      { id:"W3", a:{cId:"LMU",pinId:"PWR"}, b:{cId:"R1",pinId:"30"} },
      { id:"W4", a:{cId:"R1",pinId:"87"}, b:{cId:"L1",pinId:"A"} },
      { id:"W5", a:{cId:"L1",pinId:"B"}, b:{cId:"LMU",pinId:"GND"} }
    ],
    outs: [true,false,false]
  };
}

export default function App(){
  const [activeTab, setActiveTab] = useState<'board'|'telemetry'|'ai'|'projects'>('board');
  const [components, setComponents] = useState<any[]>(()=>getDefaultCircuit().comps);
  const [wires, setWires] = useState<any[]>(()=>getDefaultCircuit().wires);
  const [lmuOutputs, setLmuOutputs] = useState<boolean[]>(()=>getDefaultCircuit().outs);
  const [connectingPin, setConnectingPin] = useState<any>(null);
  const [selectedWireId, setSelectedWireId] = useState<string|null>(null);
  const [selectedWireCenter, setSelectedWireCenter] = useState<any>(null);
  const [analysisResult, setAnalysisResult] = useState<any>(null);
  const [nextId, setNextId] = useState(10);
  const [isAutoSaving, setIsAutoSaving] = useState(false);
  const [lastSaved, setLastSaved] = useState<Date|null>(null);
  const [savedProjects, setSavedProjects] = useState<string[]>([]);
  const [currentProjectName, setCurrentProjectName] = useState('proyecto_sin_nombre');
  const [ready, setReady] = useState(false);
  const [chatMessages, setChatMessages] = useState<any[]>([{role:'model',text:'Asistente local RUNEFORGE. Configura API key de Gemini para IA avanzada.'}]);
  const [chatInput, setChatInput] = useState('');
  const [isAiLoading, setIsAiLoading] = useState(false);

  const canvasBgRef = useRef<HTMLCanvasElement>(null);
  const canvasWiresRef = useRef<HTMLCanvasElement>(null);
  const workspaceRef = useRef<HTMLDivElement>(null);
  const animFrameRef = useRef<number>(0);
  const animProgressRef = useRef(0);
  const compPositionsRef = useRef(new Map<string,{x:number,y:number}>());
  const draggingRef = useRef<any>(null);

  const getBaseDir = useCallback(async()=> await appDataDir(),[]);
  const getProjectsDir = useCallback(async()=> await join(await appDataDir(),'proyectos'),[]);

  const ensureDirs = useCallback(async()=>{
    const base = await getBaseDir(); const dir = await getProjectsDir();
    try { if(!(await exists(base))) await mkdir(base,{recursive:true}); } catch{}
    try { if(!(await exists(dir)))  await mkdir(dir,{recursive:true}); } catch{}
  },[getBaseDir,getProjectsDir]);

  const refreshProjectsList = useCallback(async()=>{
    try {
      await ensureDirs();
      const dir = await getProjectsDir();
      const entries = await readDir(dir);
      setSavedProjects(entries.filter((e:any)=>e.name?.endsWith('.json')).map((e:any)=>e.name.replace('.json','')));
    } catch { setSavedProjects([]); }
  },[ensureDirs,getProjectsDir]);

  const saveProjectAs = useCallback(async(name:string)=>{
    try {
      await ensureDirs();
      const fp = await join(await getProjectsDir(), `${name}.json`);
      const data = { version:"1.0", lastModified:new Date().toISOString(), components, wires, lmuOutputs };
      await writeTextFile(fp, JSON.stringify(data,null,2));
      setLastSaved(new Date()); setCurrentProjectName(name);
      await refreshProjectsList(); return true;
    } catch(e){ console.error(e); return false; }
  },[components,wires,lmuOutputs,ensureDirs,getProjectsDir,refreshProjectsList]);

  const loadProject = useCallback(async(name:string)=>{
    try {
      const fp = await join(await getProjectsDir(), `${name}.json`);
      const txt = await readTextFile(fp); const data = JSON.parse(txt);
      setComponents(data.components); setWires(data.wires); setLmuOutputs(data.lmuOutputs);
      setCurrentProjectName(name); setConnectingPin(null); setSelectedWireId(null); setActiveTab('board');
    } catch(e){ console.error(e); }
  },[getProjectsDir]);

  const deleteProject = useCallback(async(name:string)=>{
    try {
      await remove(await join(await getProjectsDir(), `${name}.json`));
      await refreshProjectsList();
      if(name===currentProjectName){ const d=getDefaultCircuit(); setComponents(d.comps); setWires(d.wires); setLmuOutputs(d.outs); setCurrentProjectName('proyecto_sin_nombre'); }
    } catch(e){ console.error(e); }
  },[getProjectsDir,refreshProjectsList,currentProjectName]);

  const exportProject = useCallback(async()=>{
    try {
      const target = await save({ defaultPath:`${currentProjectName}.json`, filters:[{name:'LMU Project',extensions:['json']}] });
      if(!target) return;
      await writeTextFile(target, JSON.stringify({version:"1.0",lastModified:new Date().toISOString(),components,wires,lmuOutputs},null,2));
    } catch(e){ console.error(e); }
  },[components,wires,lmuOutputs,currentProjectName]);

  const importProject = useCallback(async()=>{
    try {
      const picked = await open({ multiple:false, filters:[{name:'LMU Project',extensions:['json']}] });
      if(!picked) return;
      const data = JSON.parse(await readTextFile(picked as string));
      setComponents(data.components); setWires(data.wires); setLmuOutputs(data.lmuOutputs);
      setCurrentProjectName('importado'); setActiveTab('board');
    } catch(e){ console.error(e); }
  },[]);

  const newProject = useCallback(()=>{
    const d = getDefaultCircuit();
    setComponents(d.comps); setWires(d.wires); setLmuOutputs(d.outs);
    setCurrentProjectName('proyecto_sin_nombre'); setActiveTab('board');
  },[]);

  useEffect(()=>{ (async()=>{
    try {
      await ensureDirs(); await refreshProjectsList();
      const auto = await join(await getBaseDir(), '_autosave.json');
      if(await exists(auto)){
        const data = JSON.parse(await readTextFile(auto));
        if(data.components){ setComponents(data.components); setWires(data.wires); setLmuOutputs(data.lmuOutputs); setCurrentProjectName(data.projectName||'recuperado'); }
      }
    } catch{}
    setReady(true);
  })(); },[ensureDirs,refreshProjectsList,getBaseDir]);

  useEffect(()=>{
    if(!ready) return;
    const t = setTimeout(async()=>{
      setIsAutoSaving(true);
      try {
        await ensureDirs();
        const auto = await join(await getBaseDir(), '_autosave.json');
        await writeTextFile(auto, JSON.stringify({version:"1.0",projectName:currentProjectName,lastModified:new Date().toISOString(),components,wires,lmuOutputs},null,2));
        setLastSaved(new Date());
      } catch(e){ console.error(e); }
      finally { setTimeout(()=>setIsAutoSaving(false),400); }
    },1200);
    return ()=>clearTimeout(t);
  },[components,wires,lmuOutputs,ready,currentProjectName,ensureDirs,getBaseDir]);

  useEffect(()=>{
    const allPins:string[]=[];
    components.forEach(c=>{ (c.type==='lmu'?LMU_PINS:COMP_PINS[c.type]).forEach((p:any)=>allPins.push(`${c.id}:${p.id}`)); });
    const ds = new DisjointSet(allPins);
    wires.forEach(w=>{ const a=`${w.a.cId}:${w.a.pinId}`, b=`${w.b.cId}:${w.b.pinId}`; if(ds.parent.has(a)&&ds.parent.has(b)) ds.union(a,b); });
    const relayStates = new Map<string,string>();
    let converged=false, iter=0;
    while(!converged && iter<15){
      iter++;
      const rm = new Map<string,any>();
      allPins.forEach(p=>{ const r=ds.find(p); if(!rm.has(r)) rm.set(r,{hasPWR:false,hasGND:false,hasOUT:false}); });
      allPins.forEach(p=>{
        const [cId,pId]=p.split(":"); const info=rm.get(ds.find(p));
        if(cId==="LMU"){
          if(pId==="PWR") info.hasPWR=true;
          if(pId==="GND") info.hasGND=true;
          if(pId.startsWith("OUT")){ const i=parseInt(pId.replace("OUT","")); if(lmuOutputs[i]) info.hasOUT=true; }
        }
      });
      components.forEach(c=>{
        if(c.type!=='relay') return;
        const r85=ds.find(`${c.id}:85`), r86=ds.find(`${c.id}:86`);
        if(r85===r86) return;
        const i85=rm.get(r85), i86=rm.get(r86); if(!i85||!i86) return;
        const on = ((i85.hasPWR||i85.hasOUT)&&i86.hasGND) || ((i86.hasPWR||i86.hasOUT)&&i85.hasGND);
        const cur = relayStates.get(c.id)==='87';
        if(on!==cur) relayStates.set(c.id, on?'87':'87a');
      });
      let changed=false;
      components.forEach(c=>{
        if(c.type!=='relay') return;
        const active = relayStates.get(c.id)||'87a';
        if(ds.parent.has(`${c.id}:30`) && ds.parent.has(`${c.id}:${active}`)){ if(ds.union(`${c.id}:30`,`${c.id}:${active}`)) changed=true; }
      });
      if(!changed && iter>1) converged=true;
    }
    const fr = new Map<string,any>();
    allPins.forEach(p=>{ const r=ds.find(p); if(!fr.has(r)) fr.set(r,{hasPWR:false,hasGND:false,hasOUT:false}); });
    allPins.forEach(p=>{
      const [cId,pId]=p.split(":"); const info=fr.get(ds.find(p));
      if(cId==="LMU"){
        if(pId==="PWR") info.hasPWR=true;
        if(pId==="GND") info.hasGND=true;
        if(pId.startsWith("OUT")){ const i=parseInt(pId.replace("OUT","")); if(lmuOutputs[i]) info.hasOUT=true; }
      }
    });
    const nodeState = new Map<string,string>();
    allPins.forEach(p=>{
      const info=fr.get(ds.find(p));
      if(info.hasPWR) nodeState.set(p,"PWR");
      else if(info.hasOUT) nodeState.set(p,"ACTIVE");
      else if(info.hasGND) nodeState.set(p,"GND");
      else nodeState.set(p,"FLOAT");
    });
    const energized=new Set<string>(), lampOn=new Set<string>();
    components.forEach(c=>{
      if(c.type==='relay'){
        const a=nodeState.get(`${c.id}:85`), b=nodeState.get(`${c.id}:86`);
        if(((a==='PWR'||a==='ACTIVE')&&b==='GND')||((b==='PWR'||b==='ACTIVE')&&a==='GND')) energized.add(c.id);
      } else if(c.type==='lamp'){
        const a=nodeState.get(`${c.id}:A`), b=nodeState.get(`${c.id}:B`);
        if(((a==='PWR'||a==='ACTIVE')&&b==='GND')||((b==='PWR'||b==='ACTIVE')&&a==='GND')) lampOn.add(c.id);
      }
    });
    const activeWires=new Set<string>();
    wires.forEach(w=>{ const s=nodeState.get(`${w.a.cId}:${w.a.pinId}`); if(s==='PWR'||s==='ACTIVE') activeWires.add(w.id); });
    setAnalysisResult({ nodeState, energized, lampOn, activeWires });
  },[components,wires,lmuOutputs]);

  const getPinAbs = useCallback((cId:string, pinId:string)=>{
    const comp = components.find(c=>c.id===cId);
    const pos = compPositionsRef.current.get(cId) || (comp?{x:comp.x,y:comp.y}:{x:0,y:0});
    const cType = comp? comp.type : (cId==="LMU"?"lmu":"relay");
    const off = PIN_OFFSETS[cType]?.[pinId] || {x:0,y:0};
    return { x:pos.x+off.x+10, y:pos.y+off.y+10 };
  },[components]);

  const draw = useCallback((progress:number)=>{
    const cW=canvasWiresRef.current, cB=canvasBgRef.current; if(!cW||!cB) return;
    const ctxW=cW.getContext('2d')!, ctxB=cB.getContext('2d')!;
    const w=cW.clientWidth, h=cW.clientHeight, dpr=window.devicePixelRatio||1;
    if(cW.width!==w*dpr){ cW.width=w*dpr; cW.height=h*dpr; cB.width=w*dpr; cB.height=h*dpr; }
    ctxB.setTransform(dpr,0,0,dpr,0,0);
    ctxB.fillStyle='#0f172a'; ctxB.fillRect(0,0,w,h);
    ctxB.strokeStyle='#1e293b'; ctxB.lineWidth=1;
    const g=24;
    for(let x=0;x<w;x+=g){ ctxB.beginPath(); ctxB.moveTo(x,0); ctxB.lineTo(x,h); ctxB.stroke(); }
    for(let y=0;y<h;y+=g){ ctxB.beginPath(); ctxB.moveTo(0,y); ctxB.lineTo(w,y); ctxB.stroke(); }
    ctxW.setTransform(dpr,0,0,dpr,0,0); ctxW.clearRect(0,0,w,h);
    wires.forEach((wr:any)=>{
      const a=getPinAbs(wr.a.cId,wr.a.pinId), b=getPinAbs(wr.b.cId,wr.b.pinId);
      const state = analysisResult?.nodeState?.get(`${wr.a.cId}:${wr.a.pinId}`)||'FLOAT';
      let color='#475569';
      if(state==='PWR') color='#ef4444'; else if(state==='ACTIVE') color='#38bdf8'; else if(state==='GND') color='#10b981';
      const dx=b.x-a.x, dy=b.y-a.y; const dist=Math.hypot(dx,dy)||1;
      const nx=-dy/dist, ny=dx/dist; const curv=35+dist*0.15;
      const cp1={x:a.x+dx*0.25+nx*curv, y:a.y+dy*0.25+ny*curv};
      const cp2={x:a.x+dx*0.75+nx*curv, y:a.y+dy*0.75+ny*curv};
      ctxW.beginPath(); ctxW.moveTo(a.x,a.y); ctxW.bezierCurveTo(cp1.x,cp1.y,cp2.x,cp2.y,b.x,b.y);
      ctxW.strokeStyle=color; ctxW.lineWidth = wr.id===selectedWireId?3.5:2.2; ctxW.lineCap='round'; ctxW.stroke();
      if(analysisResult?.activeWires?.has(wr.id)){
        const t=progress;
        const bx=Math.pow(1-t,3)*a.x+3*Math.pow(1-t,2)*t*cp1.x+3*(1-t)*t*t*cp2.x+t*t*t*b.x;
        const by=Math.pow(1-t,3)*a.y+3*Math.pow(1-t,2)*t*cp1.y+3*(1-t)*t*t*cp2.y+t*t*t*b.y;
        ctxW.beginPath(); ctxW.arc(bx,by,3,0,Math.PI*2); ctxW.fillStyle='#fff'; ctxW.fill();
        ctxW.beginPath(); ctxW.arc(bx,by,6,0,Math.PI*2); ctxW.fillStyle='rgba(56,189,248,0.3)'; ctxW.fill();
      }
    });
  },[wires,analysisResult,selectedWireId,getPinAbs]);

  useEffect(()=>{
    const loop = ()=>{ animProgressRef.current=(animProgressRef.current+0.025)%1; draw(animProgressRef.current); animFrameRef.current=requestAnimationFrame(loop); };
    animFrameRef.current=requestAnimationFrame(loop);
    return ()=>cancelAnimationFrame(animFrameRef.current);
  },[draw]);

  const onPD=(e:React.PointerEvent, cId:string)=>{
    if((e.target as HTMLElement).closest('[data-pin]')||(e.target as HTMLElement).closest('button')) return;
    const c = components.find(x=>x.id===cId); if(!c) return;
    draggingRef.current={ id:cId, startX:e.clientX, startY:e.clientY, origX:c.x, origY:c.y, el:e.currentTarget as HTMLElement };
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
  };
  const onPM=(e:React.PointerEvent)=>{
    const d=draggingRef.current; if(!d) return;
    const nx=Math.round((d.origX+e.clientX-d.startX)/12)*12;
    const ny=Math.round((d.origY+e.clientY-d.startY)/12)*12;
    d.el.style.transform=`translate3d(${nx}px,${ny}px,0)`;
    compPositionsRef.current.set(d.id,{x:nx,y:ny}); draw(animProgressRef.current);
  };
  const onPU=(e:React.PointerEvent)=>{
    const d=draggingRef.current; if(!d) return;
    try{ d.el.releasePointerCapture(e.pointerId); }catch{}
    const ws=workspaceRef.current!.getBoundingClientRect();
    const fx=Math.max(0,Math.min(ws.width-100,Math.round((d.origX+e.clientX-d.startX)/12)*12));
    const fy=Math.max(0,Math.min(ws.height-100,Math.round((d.origY+e.clientY-d.startY)/12)*12));
    d.el.style.transform=`translate3d(${fx}px,${fy}px,0)`;
    compPositionsRef.current.set(d.id,{x:fx,y:fy});
    setComponents(prev=>prev.map(c=>c.id===d.id?{...c,x:fx,y:fy}:c));
    draggingRef.current=null;
  };

  const onPinClick=(cId:string,pinId:string,e:React.MouseEvent)=>{
    e.stopPropagation();
    if(!connectingPin){ setConnectingPin({cId,pinId}); return; }
    if(connectingPin.cId===cId && connectingPin.pinId===pinId){ setConnectingPin(null); return; }
    const exists = wires.some(w=>
      (w.a.cId===connectingPin.cId&&w.a.pinId===connectingPin.pinId&&w.b.cId===cId&&w.b.pinId===pinId)||
      (w.b.cId===connectingPin.cId&&w.b.pinId===connectingPin.pinId&&w.a.cId===cId&&w.a.pinId===pinId));
    if(!exists) setWires(prev=>[...prev,{ id:`W_${Date.now()}`, a:connectingPin, b:{cId,pinId} }]);
    setConnectingPin(null);
  };

  const onWsClick=(e:React.MouseEvent)=>{
    if(connectingPin) setConnectingPin(null);
    const ws=workspaceRef.current!.getBoundingClientRect();
    const cx=e.clientX-ws.left, cy=e.clientY-ws.top;
    let found:any=null, min=20;
    wires.forEach(w=>{
      const a=getPinAbs(w.a.cId,w.a.pinId), b=getPinAbs(w.b.cId,w.b.pinId);
      const d=Math.hypot((a.x+b.x)/2-cx,(a.y+b.y)/2-cy);
      if(d<min){ min=d; found=w; }
    });
    if(found){ setSelectedWireId(found.id);
      const a=getPinAbs(found.a.cId,found.a.pinId), b=getPinAbs(found.b.cId,found.b.pinId);
      setSelectedWireCenter({x:(a.x+b.x)/2,y:(a.y+b.y)/2});
    } else { setSelectedWireId(null); setSelectedWireCenter(null); }
  };

  const addRelay=()=>{ const id=`R${nextId}`; setNextId(n=>n+1); setComponents(p=>[...p,{id,type:'relay',x:80+Math.random()*120,y:180+Math.random()*80}]); };
  const addLamp=()=>{ const id=`L${nextId}`; setNextId(n=>n+1); setComponents(p=>[...p,{id,type:'lamp',x:220+Math.random()*120,y:200+Math.random()*80}]); };
  const resetCircuit=()=>{ const d=getDefaultCircuit(); setComponents(d.comps); setWires(d.wires); setLmuOutputs(d.outs); setConnectingPin(null); setSelectedWireId(null); };

  const handleSend = async(custom:string|null=null)=>{
    const txt = custom||chatInput; if(!txt.trim()) return;
    setChatMessages(p=>[...p,{role:'user',text:txt}]); if(!custom) setChatInput('');
    setIsAiLoading(true);
    const summary = {
      components: components.map(c=>({id:c.id,type:c.type})),
      wiresCount: wires.length,
      lmuOutputsActive: lmuOutputs.map((v,i)=>`OUT${i}:${v}`).join(', '),
      energizedRelays: Array.from(analysisResult?.energized||[]),
      activeLamps: Array.from(analysisResult?.lampOn||[])
    };
    const key = localStorage.getItem('gemini_api_key')||'';
    if(!key){
      setChatMessages(p=>[...p,{role:'model',text:`Análisis local:\n• Componentes: ${summary.components.length}\n• Cables: ${summary.wiresCount}\n• ${summary.lmuOutputsActive}\n• Relés activos: ${summary.energizedRelays.join(', ')||'ninguno'}\n• Lámparas ON: ${summary.activeLamps.join(', ')||'ninguna'}\n\n(Configura API key de Gemini para IA avanzada)`}]);
      setIsAiLoading(false); return;
    }
    try {
      const sys = `Eres ingeniero electrónico experto en CalAmp LMU-2630. Estado: ${JSON.stringify(summary)}. Responde en español técnico y conciso.`;
      const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${key}`,{
        method:'POST', headers:{'Content-Type':'application/json'},
        body:JSON.stringify({contents:[{role:'user',parts:[{text:`${sys}\n\nConsulta: ${txt}`}]}]})
      });
      const j = await res.json();
      setChatMessages(p=>[...p,{role:'model',text:j.candidates?.[0]?.content?.parts?.[0]?.text||'Sin respuesta.'}]);
    } catch { setChatMessages(p=>[...p,{role:'model',text:'⚠️ Error de red.'}]); }
    finally { setIsAiLoading(false); }
  };

  if(!ready) return (
    <div className="flex h-screen w-screen items-center justify-center bg-slate-950 text-cyan-400 font-mono text-sm">
      <RefreshCw className="w-4 h-4 animate-spin mr-2"/> Inicializando RUNEFORGE LMU-HMI...
    </div>
  );

  return (
    <div className="flex flex-col h-[100dvh] w-screen bg-slate-950 text-slate-100 font-sans select-none overflow-hidden">
      <header className="flex items-center justify-between px-4 py-2.5 bg-slate-900 border-b border-slate-800 z-30 shrink-0">
        <div className="flex items-center space-x-2">
          <div className="w-2.5 h-2.5 rounded-full bg-cyan-400 animate-pulse"/>
          <h1 className="text-xs font-mono font-bold tracking-wider text-cyan-400">LMU-2630 <span className="text-slate-400 font-normal">HMI · RUNEFORGE</span></h1>
        </div>
        <div className="flex items-center space-x-1.5">
          {lmuOutputs.map((a,i)=>(
            <button key={i} onClick={()=>setLmuOutputs(p=>{const n=[...p];n[i]=!n[i];return n;})}
              className={`px-2.5 py-1 rounded-full text-[10px] font-mono font-bold border transition-all ${a?'bg-cyan-500/20 border-cyan-500 text-cyan-300':'bg-slate-800 border-slate-700 text-slate-400'}`}>
              OUT{i}
            </button>
          ))}
        </div>
      </header>

      <div className="absolute top-12 right-3 z-40 flex items-center gap-2 pointer-events-none">
        {isAutoSaving ? (
          <span className="text-[10px] font-mono text-cyan-400 flex items-center gap-1 bg-slate-900/95 px-2 py-1 rounded-full border border-cyan-500/30">
            <RefreshCw className="w-3 h-3 animate-spin"/> Guardando...
          </span>
        ) : lastSaved ? (
          <span className="text-[10px] font-mono text-emerald-400 flex items-center gap-1 bg-slate-900/95 px-2 py-1 rounded-full border border-emerald-500/30">
            <Save className="w-3 h-3"/> {lastSaved.toLocaleTimeString()} · {currentProjectName}
          </span>
        ):null}
      </div>

      <main className="flex-1 flex flex-col relative overflow-hidden pb-16">
        {activeTab==='board' && (
          <div ref={workspaceRef} onClick={onWsClick} className="flex-1 relative overflow-hidden bg-slate-950 cursor-crosshair touch-none">
            <canvas ref={canvasBgRef} className="absolute inset-0 w-full h-full pointer-events-none"/>
            <canvas ref={canvasWiresRef} className="absolute inset-0 w-full h-full pointer-events-none"/>
            {components.map(comp=>{
              const pos = compPositionsRef.current.get(comp.id)||{x:comp.x,y:comp.y};
              const isRelay = comp.type==='relay', isLamp = comp.type==='lamp', isLmu = comp.type==='lmu';
              const eR = isRelay && analysisResult?.energized?.has(comp.id);
              const lOn = isLamp && analysisResult?.lampOn?.has(comp.id);
              const pins = isLmu? LMU_PINS : COMP_PINS[comp.type];
              return (
                <div key={comp.id} onPointerDown={e=>onPD(e,comp.id)} onPointerMove={onPM} onPointerUp={onPU}
                  className="absolute cursor-grab active:cursor-grabbing touch-none select-none"
                  style={{transform:`translate3d(${pos.x}px,${pos.y}px,0)`,width:COMP_SIZES[comp.type].w,height:COMP_SIZES[comp.type].h,zIndex:10}}>
                  {isLmu && (
                    <div className="w-full h-full bg-[#0a2e21] border border-[#10b981]/40 rounded-xl p-3 shadow-2xl flex flex-col justify-between">
                      <div className="flex justify-between items-center">
                        <span className="text-[10px] font-mono font-bold text-emerald-400 tracking-wider">LMU-2630 EDGE</span>
                        <span className="text-[9px] font-mono text-slate-400">12V ECU</span>
                      </div>
                      <div className="bg-slate-950/80 rounded-lg p-2 border border-emerald-900/50 flex items-center justify-between">
                        <div className="flex items-center space-x-1.5"><div className="w-2 h-2 rounded-full bg-rose-500"/><span className="text-[9px] text-slate-300 font-mono">PWR</span></div>
                        <div className="flex items-center space-x-1.5"><div className="w-2 h-2 rounded-full bg-emerald-500"/><span className="text-[9px] text-slate-300 font-mono">GND</span></div>
                      </div>
                    </div>
                  )}
                  {isRelay && (
                    <div className={`w-full h-full bg-slate-900 border rounded-xl p-2.5 shadow-xl flex flex-col justify-between transition-colors ${eR?'border-amber-500 shadow-[0_0_15px_rgba(245,158,11,0.3)]':'border-slate-700'}`}>
                      <div className="flex justify-between items-center">
                        <span className="text-[10px] font-mono font-bold text-slate-300">{comp.id}</span>
                        <div className={`w-2 h-2 rounded-full ${eR?'bg-amber-400 shadow-[0_0_8px_#f59e0b]':'bg-slate-700'}`}/>
                      </div>
                      <div className="bg-slate-950 rounded-lg h-8 flex items-center justify-center border border-slate-800">
                        <span className="text-[9px] font-mono text-slate-400">{eR?'NO Closed':'NC Closed'}</span>
                      </div>
                    </div>
                  )}
                  {isLamp && (
                    <div className="w-full h-full flex flex-col items-center justify-center">
                      <div className={`w-14 h-14 rounded-full border-2 flex items-center justify-center transition-all ${lOn?'bg-amber-200 border-amber-400 shadow-[0_0_25px_#fde047,inset_0_0_10px_#ca8a04]':'bg-slate-900 border-slate-700 shadow-md'}`}>
                        <span className="text-lg">💡</span>
                      </div>
                      <span className="text-[9px] font-mono text-slate-400 mt-1">{comp.id}</span>
                    </div>
                  )}
                  {pins.map((pin:any)=>{
                    const state = analysisResult?.nodeState?.get(`${comp.id}:${pin.id}`)||'FLOAT';
                    const isSel = connectingPin?.cId===comp.id && connectingPin?.pinId===pin.id;
                    const off = PIN_OFFSETS[comp.type][pin.id];
                    let bg='#334155';
                    if(state==='PWR') bg='#ef4444'; else if(state==='ACTIVE') bg='#38bdf8'; else if(state==='GND') bg='#10b981';
                    return (
                      <div key={pin.id} data-pin onClick={e=>onPinClick(comp.id,pin.id,e)}
                        className={`absolute w-5 h-5 rounded-full border-2 cursor-pointer flex items-center justify-center transition-transform z-20 ${isSel?'scale-125 border-white shadow-[0_0_12px_#fff]':'border-slate-900 hover:scale-110'}`}
                        style={{left:off.x,top:off.y,backgroundColor:bg,boxShadow:state!=='FLOAT'?`0 0 8px ${bg}`:'none'}}>
                        <div className="w-1.5 h-1.5 rounded-full bg-slate-950"/>
                      </div>
                    );
                  })}
                </div>
              );
            })}
            {selectedWireId && selectedWireCenter && (
              <button onClick={()=>{setWires(p=>p.filter(w=>w.id!==selectedWireId));setSelectedWireId(null);setSelectedWireCenter(null);}}
                className="absolute bg-rose-600 hover:bg-rose-500 text-white p-2 rounded-full shadow-2xl z-40 transform -translate-x-1/2 -translate-y-1/2"
                style={{left:selectedWireCenter.x,top:selectedWireCenter.y}}>
                <Trash2 className="w-4 h-4"/>
              </button>
            )}
            {connectingPin && (
              <div className="absolute top-3 left-1/2 -translate-x-1/2 bg-cyan-950/90 border border-cyan-500/50 text-cyan-300 px-3 py-1.5 rounded-full text-xs font-mono z-30 animate-pulse">
                Conectando {connectingPin.cId}:{connectingPin.pinId} — toca destino
              </div>
            )}
          </div>
        )}

        {activeTab==='telemetry' && (
          <div className="flex-1 p-4 space-y-4 overflow-y-auto bg-slate-950">
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
              <h2 className="text-xs font-bold font-mono text-cyan-400 uppercase flex items-center mb-3">
                <Activity className="w-4 h-4 mr-1.5"/> Canales LMU-2630
              </h2>
              <div className="grid grid-cols-3 gap-2">
                {lmuOutputs.map((s,i)=>(
                  <div key={i} className="bg-slate-950 p-3 rounded-lg border border-slate-800">
                    <span className="text-[10px] text-slate-500 font-mono">OUT-{i}</span>
                    <div className={`text-sm font-bold font-mono mt-1 ${s?'text-cyan-400':'text-slate-500'}`}>{s?'ACTIVO':'ABIERTO'}</div>
                  </div>
                ))}
              </div>
            </div>
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
              <h2 className="text-xs font-bold font-mono text-cyan-400 uppercase flex items-center mb-3">
                <Cpu className="w-4 h-4 mr-1.5"/> Diagnóstico
              </h2>
              <div className="space-y-2 text-xs font-mono">
                <div className="flex justify-between py-1.5 border-b border-slate-800"><span className="text-slate-400">Componentes</span><span className="text-cyan-400">{components.length}</span></div>
                <div className="flex justify-between py-1.5 border-b border-slate-800"><span className="text-slate-400">Cables</span><span className="text-cyan-400">{wires.length}</span></div>
                <div className="flex justify-between py-1.5 border-b border-slate-800"><span className="text-slate-400">Relés activos</span><span className="text-amber-400">{Array.from(analysisResult?.energized||[]).join(', ')||'—'}</span></div>
                <div className="flex justify-between py-1.5"><span className="text-slate-400">Lámparas ON</span><span className="text-yellow-400">{Array.from(analysisResult?.lampOn||[]).join(', ')||'—'}</span></div>
              </div>
            </div>
          </div>
        )}

        {activeTab==='ai' && (
          <div className="flex-1 flex flex-col p-4 bg-slate-950 overflow-hidden">
            <div className="bg-purple-950/20 border border-purple-500/30 p-3 rounded-xl mb-3 flex items-center justify-between">
              <div>
                <h2 className="text-xs font-bold text-purple-300 flex items-center gap-1.5"><Sparkles className="w-4 h-4 text-purple-400 animate-pulse"/> Asistente Gemini</h2>
                <p className="text-[11px] text-slate-400 mt-0.5">{components.length} componentes · {wires.length} conexiones</p>
              </div>
              <button onClick={()=>handleSend("Analiza mi circuito y dame recomendaciones.")}
                className="px-2.5 py-1.5 bg-purple-600 hover:bg-purple-500 text-white rounded-lg text-xs font-semibold flex items-center gap-1">
                <Cpu className="w-3.5 h-3.5"/> Diagnosticar
              </button>
            </div>
            <div className="flex-1 bg-slate-900 border border-slate-800 rounded-xl p-3 overflow-y-auto space-y-3 text-xs font-mono">
              {chatMessages.map((m,i)=>(
                <div key={i} className={`flex flex-col ${m.role==='user'?'items-end':'items-start'}`}>
                  <div className={`max-w-[85%] p-3 rounded-xl whitespace-pre-wrap ${m.role==='user'?'bg-cyan-950/60 border border-cyan-500/30 text-cyan-200 rounded-br-none':'bg-purple-950/40 border border-purple-500/30 text-purple-200 rounded-bl-none'}`}>
                    <div className="text-[9px] opacity-70 mb-1 font-bold">{m.role==='user'?'Operador':'Gemini'}</div>
                    {m.text}
                  </div>
                </div>
              ))}
              {isAiLoading && <div className="flex items-center space-x-2 text-purple-400 p-2 animate-pulse"><Sparkles className="w-4 h-4 animate-spin"/><span>Analizando topología...</span></div>}
            </div>
            <div className="mt-3 flex gap-2">
              <input type="text" value={chatInput} onChange={e=>setChatInput(e.target.value)} onKeyDown={e=>e.key==='Enter'&&handleSend()}
                placeholder="Pregunta a Gemini..."
                className="flex-1 bg-slate-900 border border-slate-800 rounded-xl px-3 py-2.5 text-xs text-white focus:outline-none focus:border-purple-500"/>
              <button onClick={()=>handleSend()} disabled={isAiLoading}
                className="bg-purple-600 hover:bg-purple-500 text-white px-4 py-2.5 rounded-xl text-xs font-bold flex items-center justify-center disabled:opacity-50">
                <Send className="w-4 h-4"/>
              </button>
            </div>
          </div>
        )}

        {activeTab==='projects' && (
          <div className="flex-1 p-4 space-y-4 overflow-y-auto bg-slate-950">
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xs font-bold font-mono text-cyan-400 uppercase flex items-center">
                  <FolderOpen className="w-4 h-4 mr-1.5"/> Mis Proyectos
                </h2>
                <div className="flex gap-2">
                  <button onClick={newProject} className="px-3 py-1.5 bg-cyan-600 hover:bg-cyan-500 text-white rounded-lg text-xs font-semibold flex items-center gap-1"><Plus className="w-3.5 h-3.5"/> Nuevo</button>
                  <button onClick={importProject} className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 text-white rounded-lg text-xs font-semibold flex items-center gap-1"><Upload className="w-3.5 h-3.5"/> Importar</button>
                </div>
              </div>
              {savedProjects.length===0 ? (
                <div className="text-center py-8 text-slate-500">
                  <FolderOpen className="w-12 h-12 mx-auto mb-2 opacity-30"/>
                  <p className="text-sm">No hay proyectos guardados.</p>
                  <p className="text-xs mt-1">El circuito se autoguarda automáticamente.</p>
                </div>
              ) : (
                <div className="space-y-2">
                  {savedProjects.map(p=>(
                    <div key={p} className={`flex items-center justify-between p-3 rounded-lg border ${p===currentProjectName?'bg-cyan-950/30 border-cyan-500/50':'bg-slate-800/50 border-slate-700'}`}>
                      <div className="flex items-center gap-3">
                        <FileText className="w-4 h-4 text-slate-400"/>
                        <span className="text-sm font-mono text-slate-200">{p}</span>
                        {p===currentProjectName && <span className="text-[10px] text-cyan-400 font-bold">ACTUAL</span>}
                      </div>
                      <div className="flex gap-1">
                        <button onClick={()=>loadProject(p)} className="p-1.5 hover:bg-slate-700 rounded text-cyan-400"><FolderOpen className="w-3.5 h-3.5"/></button>
                        <button onClick={()=>deleteProject(p)} className="p-1.5 hover:bg-slate-700 rounded text-rose-400"><Trash2 className="w-3.5 h-3.5"/></button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-4">
              <h3 className="text-xs font-bold font-mono text-slate-400 uppercase mb-3">Acciones</h3>
              <div className="flex gap-2">
                <button onClick={()=>saveProjectAs(currentProjectName)} className="flex-1 px-3 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center gap-1"><Save className="w-3.5 h-3.5"/> Guardar Ahora</button>
                <button onClick={exportProject} className="flex-1 px-3 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-lg text-xs font-semibold flex items-center justify-center gap-1"><Download className="w-3.5 h-3.5"/> Exportar</button>
              </div>
            </div>
          </div>
        )}
      </main>

      <nav className="absolute bottom-0 left-0 right-0 h-16 bg-slate-900 border-t border-slate-800 flex justify-around items-center px-2 z-40">
        {activeTab==='board' && (<>
          <button onClick={addRelay} className="flex flex-col items-center justify-center flex-1 h-full text-slate-400 hover:text-cyan-400"><Plus className="w-4 h-4 text-amber-400"/><span className="text-[10px] font-mono mt-0.5">Relé</span></button>
          <button onClick={addLamp} className="flex flex-col items-center justify-center flex-1 h-full text-slate-400 hover:text-cyan-400"><Plus className="w-4 h-4 text-yellow-400"/><span className="text-[10px] font-mono mt-0.5">Lámpara</span></button>
          <button onClick={resetCircuit} className="flex flex-col items-center justify-center flex-1 h-full text-slate-400 hover:text-rose-400"><RotateCcw className="w-4 h-4"/><span className="text-[10px] font-mono mt-0.5">Reset</span></button>
        </>)}
        <div className="w-[1px] h-8 bg-slate-800 mx-1"/>
        <button onClick={()=>setActiveTab('board')} className={`flex flex-col items-center justify-center flex-1 h-full ${activeTab==='board'?'text-cyan-400 font-bold':'text-slate-500'}`}><Layers className="w-4 h-4"/><span className="text-[10px] font-mono mt-0.5">Tablero</span></button>
        <button onClick={()=>setActiveTab('telemetry')} className={`flex flex-col items-center justify-center flex-1 h-full ${activeTab==='telemetry'?'text-cyan-400 font-bold':'text-slate-500'}`}><Activity className="w-4 h-4"/><span className="text-[10px] font-mono mt-0.5">Sensores</span></button>
        <button onClick={()=>setActiveTab('ai')} className={`flex flex-col items-center justify-center flex-1 h-full ${activeTab==='ai'?'text-purple-400 font-bold':'text-slate-500'}`}><Sparkles className="w-4 h-4"/><span className="text-[10px] font-mono mt-0.5">IA</span></button>
        <button onClick={()=>{setActiveTab('projects');refreshProjectsList();}} className={`flex flex-col items-center justify-center flex-1 h-full ${activeTab==='projects'?'text-cyan-400 font-bold':'text-slate-500'}`}><FolderOpen className="w-4 h-4"/><span className="text-[10px] font-mono mt-0.5">Proyectos</span></button>
      </nav>
    </div>
  );
}
'@
Set-Content -Path "src\App.tsx" -Value $appTsx -Encoding UTF8

# =====================================================================
# FIX CRÍTICO #4: npm install con retry y fallback HTTP registry
# =====================================================================
function Invoke-NpmInstall {
    param([string]$Packages, [string]$ExtraArgs = "")
    $args = @("install", "--no-audit", "--no-fund", "--loglevel=error")
    if ($ExtraArgs) { $args += $ExtraArgs.Split(" ") }
    $args += $Packages.Split(" ")
    & $npm @args
    return $LASTEXITCODE
}

Write-Host "[2/6] Instalando dependencias runtime..." -ForegroundColor DarkCyan
$runtimePkgs = "react react-dom lucide-react @tauri-apps/api@^2 @tauri-apps/plugin-fs@^2 @tauri-apps/plugin-dialog@^2 @tauri-apps/plugin-store@^2"
$rc = Invoke-NpmInstall -Packages $runtimePkgs
if ($rc -ne 0) {
    Write-Host "[!] Reintentando con registry HTTP (evita handshake TLS)..." -ForegroundColor Yellow
    & $npm config set registry "http://registry.npmjs.org/" 2>&1 | Out-Null
    Invoke-FullCleanup
    Start-Sleep -Seconds 2
    $rc = Invoke-NpmInstall -Packages $runtimePkgs
    if ($rc -ne 0) {
        Write-Host "[!] Reintentando con espejo npmmirror..." -ForegroundColor Yellow
        & $npm config set registry "https://registry.npmmirror.com/" 2>&1 | Out-Null
        Invoke-FullCleanup
        Start-Sleep -Seconds 2
        $rc = Invoke-NpmInstall -Packages $runtimePkgs
        if ($rc -ne 0) { Write-Host "[X] Fallo npm runtime tras 3 intentos." -ForegroundColor Red; exit 1 }
    }
    & $npm config set registry "https://registry.npmjs.org/" 2>&1 | Out-Null
}
Write-Host "[OK] Runtime instalado." -ForegroundColor Green

Write-Host "[3/6] Instalando dependencias dev..." -ForegroundColor DarkCyan
$devPkgs = "vite @vitejs/plugin-react typescript @types/react @types/react-dom tailwindcss@^3 postcss autoprefixer @tauri-apps/cli@^2"
$rc = Invoke-NpmInstall -Packages $devPkgs -ExtraArgs "-D"
if ($rc -ne 0) {
    Write-Host "[!] Reintentando dev con registry HTTP..." -ForegroundColor Yellow
    & $npm config set registry "http://registry.npmjs.org/" 2>&1 | Out-Null
    Invoke-FullCleanup
    Start-Sleep -Seconds 2
    $rc = Invoke-NpmInstall -Packages $devPkgs -ExtraArgs "-D"
    if ($rc -ne 0) { Write-Host "[X] Fallo npm dev tras 2 intentos." -ForegroundColor Red; exit 1 }
    & $npm config set registry "https://registry.npmjs.org/" 2>&1 | Out-Null
}
Write-Host "[OK] Dev instalado." -ForegroundColor Green

$tauriCmd = Join-Path $PWD "node_modules\.bin\tauri.cmd"
if (-not (Test-Path $tauriCmd)) { Write-Host "[X] tauri CLI no instalado." -ForegroundColor Red; exit 1 }
Write-Host "[OK] tauri CLI: $tauriCmd" -ForegroundColor Green

# ---------- 6. Tauri init ----------
Write-Host "[4/6] Tauri init..." -ForegroundColor DarkCyan
& $tauriCmd init `
    --app-name "lmu-hmi" `
    --window-title "LMU-2630 HMI" `
    --frontend-dist "../dist" `
    --dev-url "http://localhost:5173" `
    --before-dev-command "npm run dev" `
    --before-build-command "npm run build" `
    --ci

if (-not (Test-Path "src-tauri")) {
    Write-Host "[!] tauri init no generó src-tauri, creando manualmente..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "src-tauri\src" -Force | Out-Null
    New-Item -ItemType Directory -Path "src-tauri\capabilities" -Force | Out-Null
    New-Item -ItemType Directory -Path "src-tauri\icons" -Force | Out-Null

    @'
[package]
name = "lmu-hmi"
version = "1.0.0"
description = "LMU-2630 HMI Desktop"
edition = "2021"

[lib]
name = "lmu_hmi_lib"
crate-type = ["staticlib", "cdylib", "rlib"]

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = [] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tauri-plugin-fs = "2"
tauri-plugin-dialog = "2"
tauri-plugin-store = "2"
'@ | Set-Content "src-tauri\Cargo.toml" -Encoding UTF8

    @'
fn main() { tauri_build::build() }
'@ | Set-Content "src-tauri\build.rs" -Encoding UTF8

    @'
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
fn main() { lmu_hmi_lib::run() }
'@ | Set-Content "src-tauri\src\main.rs" -Encoding UTF8

    @'
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
'@ | Set-Content "src-tauri\src\lib.rs" -Encoding UTF8

    @'
{
  "$schema": "https://schema.tauri.app/config/2",
  "productName": "LMU-2630 HMI",
  "version": "1.0.0",
  "identifier": "com.runeforge.lmu-hmi",
  "build": {
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build",
    "devUrl": "http://localhost:5173",
    "frontendDist": "../dist"
  },
  "app": {
    "windows": [{ "title": "LMU-2630 HMI", "width": 1280, "height": 800, "resizable": true }],
    "security": { "csp": null }
  },
  "bundle": {
    "active": true,
    "targets": "all",
    "icon": ["icons/32x32.png","icons/128x128.png","icons/icon.png"]
  }
}
'@ | Set-Content "src-tauri\tauri.conf.json" -Encoding UTF8

    @'
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "default",
  "description": "Default capability",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "path:default",
    "dialog:default",
    "dialog:allow-open",
    "dialog:allow-save",
    "fs:default",
    "fs:allow-appdata-read-recursive",
    "fs:allow-appdata-write-recursive",
    "fs:allow-appdata-meta-recursive",
    "store:default"
  ]
}
'@ | Set-Content "src-tauri\capabilities\default.json" -Encoding UTF8
}

# ---------- 7. Iconos ----------
Write-Host "[5/6] Generando iconos..." -ForegroundColor DarkCyan
Add-Type -AssemblyName System.Drawing
$sizes = @{ "32x32.png"=32; "128x128.png"=128; "128x128@2x.png"=256; "icon.png"=512 }
foreach ($kv in $sizes.GetEnumerator()) {
    $size = $kv.Value
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::FromArgb(15, 23, 42))
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(56, 189, 248))
    $margin = [int]($size * 0.18)
    $g.FillEllipse($brush, $margin, $margin, $size - 2*$margin, $size - 2*$margin)
    $bmp.Save((Join-Path $PWD "src-tauri\icons\$($kv.Key)"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose(); $g.Dispose(); $brush.Dispose()
}
Write-Host "[OK] Iconos generados." -ForegroundColor Green

# ---------- 8. Normalizar ----------
$cargoPath = "src-tauri\Cargo.toml"
$cargo = Get-Content $cargoPath -Raw
if ($cargo -notmatch "\[lib\]") {
    $cargo += "`n[lib]`nname = `"lmu_hmi_lib`"`ncrate-type = [`"staticlib`", `"cdylib`", `"rlib`"]`n"
}
foreach ($plug in @("tauri-plugin-fs","tauri-plugin-dialog","tauri-plugin-store")) {
    if ($cargo -notmatch [regex]::Escape($plug)) {
        $cargo = $cargo -replace "(?m)^(\[dependencies\])", "`$1`n$plug = `"2`""
    }
}
Set-Content $cargoPath $cargo -Encoding UTF8

@'
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
'@ | Set-Content "src-tauri\src\lib.rs" -Encoding UTF8

@'
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
fn main() { lmu_hmi_lib::run() }
'@ | Set-Content "src-tauri\src\main.rs" -Encoding UTF8

# ---------- 9. Build Vite ----------
Write-Host "[6/6] Verificando build del frontend..." -ForegroundColor DarkCyan
& $npm run build
if ($LASTEXITCODE -ne 0 -or -not (Test-Path "dist\index.html")) {
    Write-Host "[X] Fallo el build de Vite." -ForegroundColor Red; exit 1
}
Write-Host "[OK] dist/index.html generado." -ForegroundColor Green

# ---------- 10. Lanzar ----------
Write-Host ""
Write-Host "[RUNEFORGE] Compilando Tauri (5-15 min primera vez)..." -ForegroundColor Green
Write-Host ""
& $tauriCmd dev