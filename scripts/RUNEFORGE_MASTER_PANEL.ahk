; ================================
; RUNEFORGE MASTER PANEL V8
; AutoHotkey v2 - Integración de Memoria, Docs y Git
; ================================

#Requires AutoHotkey v2.0
#SingleInstance Force

global RF := Map(
    "ROOT", "C:\RUNEFORGE_V2_CORE",
    "FIRMWARE", "C:\RUNEFORGE_V2_CORE\firmware",
    "PUBLIC", "C:\RUNEFORGE_V2_CORE\public",
    "FORJA", "C:\RUNEFORGE_V2_CORE\forja",
    "SCRIPTS", "C:\RUNEFORGE_V2_CORE\scripts",
    "DOCS", "C:\RUNEFORGE_V2_CORE\docs\md",
    "REPORTS", "C:\RUNEFORGE_V2_CORE\reports",
    "DATA", "C:\RUNEFORGE_V2_CORE\core_data",
    
    ; Archivos Clave
    "MASTER_DASH", "C:\RUNEFORGE_V2_CORE\public\dashboards\index_master_V25_FINAL.html",
    "MASTER_RADAR", "C:\RUNEFORGE_V2_CORE\firmware\scannerpro_cyber_visualizer\scannerpro_cyber_visualizer.html",
    "MASTER_GPS", "C:\RUNEFORGE_V2_CORE\public\dashboards\fusionada_x5f_sonar_x5f_instalaciones_x5f_sepcolgps.html",

    ; Prompts y Memoria
    "PROMPTS_DIR", "C:\RUNEFORGE_V2_CORE\core_data\prompts",
    "MEMORIAS_DIR", "C:\RUNEFORGE_V2_CORE\core_data\memorias",
    "MEMORIA", "C:\RUNEFORGE_V2_CORE\core_data\memorias\memoria_operativa.txt",
    "PROMPT_MAESTRO", "C:\RUNEFORGE_V2_CORE\core_data\prompts\prompt_maestro.txt",
    
    ; Documentación (Memoria del Proyecto)
    "DOC_MANIFIESTO", "C:\RUNEFORGE_V2_CORE\docs\md\MANIFIESTO.md",
    "DOC_ARQUITECTURA", "C:\RUNEFORGE_V2_CORE\docs\md\RUNEFORGE_V2_CORE.md",
    "DOC_NEXUS", "C:\RUNEFORGE_V2_CORE\docs\md\NEXUS_ARCHITECT_AUTOMATION.md",

    ; Batch Scripts (System Ops)
    "BAT_BOOT", "C:\RUNEFORGE_V2_CORE\scripts\RUNEFORGE.bat",
    "BAT_STOP", "C:\RUNEFORGE_V2_CORE\scripts\STOP.bat",
    "BAT_AUDIT", "C:\RUNEFORGE_V2_CORE\scripts\AUDIT.bat",
    "BAT_RESET", "C:\RUNEFORGE_V2_CORE\scripts\RESET.bat"
)

; ========= AUTOSETUP =========
EnsureBase() {
    for _, dir in [RF["ROOT"], RF["FIRMWARE"], RF["PUBLIC"], RF["FORJA"], RF["SCRIPTS"], RF["DOCS"], RF["REPORTS"], RF["DATA"], RF["PROMPTS_DIR"], RF["MEMORIAS_DIR"]] {
        if !DirExist(dir)
            DirCreate(dir)
    }
}

; ========= UTILIDADES =========
CopyText(text) => A_Clipboard := text
CopyFile(path) => (FileExist(path) ? A_Clipboard := FileRead(path, "UTF-8") : MsgBox("Archivo no encontrado: " path, "Error"))
OpenPath(path) => (FileExist(path) || DirExist(path) ? Run(path) : MsgBox("Ruta no encontrada: " path, "Error"))
EditFile(path) => (FileExist(path) ? Run('notepad.exe "' path '"') : MsgBox("Archivo no encontrado: " path, "Error"))
RunPowerShell(cmd) => Run('pwsh -NoExit -Command ' cmd)

; Lógica robusta para ejecutar .bat o .ps1 si el .bat no existe
RunBat(path) {
    if FileExist(path) {
        Run('"' path '"')
    } else {
        ps1Path := StrReplace(path, ".bat", ".ps1")
        if FileExist(ps1Path) {
            Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' ps1Path '"')
        } else {
            MsgBox("No se encontró el script:`n" path, "Error", "Icon!")
        }
    }
}

; Lógica para Git Push
RunGitPush() {
    gitPs1 := RF["SCRIPTS"] "\rf-git.ps1"
    if FileExist(gitPs1) {
        Run('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' gitPs1 '"')
    } else {
        MsgBox("No se encontró rf-git.ps1 en " RF["SCRIPTS"], "Error", "Icon!")
    }
}

SearchInRepo(*) {
    ib := InputBox("Texto a buscar en C:\RUNEFORGE_V2_CORE:", "Buscar en Código")
    if (ib.Result != "OK" || Trim(ib.Value) = "")
        return
    safeBase := '"' RF["ROOT"] '"'
    safeTerm := StrReplace(Trim(ib.Value), '"', '\"')
    Run('cmd.exe /k cd /d ' safeBase ' && (rg -n --hidden --glob "!node_modules" --glob "!target" "' safeTerm '" || findstr /s /i /n "' safeTerm '" *.*)')
}

CreateModule(*) {
    ib := InputBox("Nombre del módulo (ej. scanner_v2):", "Crear Módulo")
    if (ib.Result != "OK" || Trim(ib.Value) = "")
        return
    name := RegExReplace(Trim(ib.Value), "[^\w\-]", "_")
    file := RF["FORJA"] "\" name ".ts"
    if FileExist(file) {
        MsgBox("Ya existe:`n" file, "Aviso")
        return
    }
    content := "export function " name "() {`n    return { ok: true, module: '" name "', ts: new Date().toISOString() };`n}`n"
    FileAppend(content, file, "UTF-8")
    Run('notepad.exe "' file '"')
}

CopySnippetFastify(*) {
    A_Clipboard := "import { FastifyInstance } from 'fastify';`n`nexport async function registerRoutes(app: FastifyInstance) {`n    app.get('/health', async () => ({ ok: true, service: 'runeforge' }));`n}`n"
}

CopySnippetPS(*) {
    A_Clipboard := "$ErrorActionPreference = 'Stop'`n`n$result = [pscustomobject]@{`n    ok = $true`n    ts = (Get-Date).ToString('s')`n}`n`n$result | ConvertTo-Json -Depth 5`n"
}

; ========= INIT =========
EnsureBase()

; ========= GUI =========
myGui := Gui("+AlwaysOnTop +Resize", "RUNEFORGE COMMAND CENTER V8")
myGui.BackColor := "0D0211"
myGui.SetFont("s10 c39FF14", "Segoe UI")

title := myGui.AddText("xm w430 Center c39FF14", "⚡ RUNEFORGE COMMAND CENTER V8")
title.SetFont("s14 Bold", "Segoe UI")

; ===== BLOQUE 1: MASTERS =====
myGui.AddGroupBox("xm y+10 w430 h70 c39FF14", " MASTERS (UI) ")
myGui.AddButton("xm+15 yp+28 w125 h30", "📊 Dashboard").OnEvent("Click", (*) => OpenPath(RF["MASTER_DASH"]))
myGui.AddButton("x+10 w125 h30", "📡 Radar BLE").OnEvent("Click", (*) => OpenPath(RF["MASTER_RADAR"]))
myGui.AddButton("x+10 w125 h30", "📍 GPS/Sonar").OnEvent("Click", (*) => OpenPath(RF["MASTER_GPS"]))

; ===== BLOQUE 2: IA / CONTEXTO =====
myGui.AddGroupBox("xm y+15 w430 h150 c39FF14", " IA / CONTEXTO ")
myGui.AddButton("xm+15 yp+28 w125 h30", "🧠 Memoria Ops").OnEvent("Click", (*) => CopyFile(RF["MEMORIA"]))
myGui.AddButton("x+10 w125 h30", "📜 Prompt Master").OnEvent("Click", (*) => CopyFile(RF["PROMPT_MAESTRO"]))
myGui.AddButton("x+10 w125 h30", "💬 ChatGPT").OnEvent("Click", (*) => Run("https://chatgpt.com/"))

myGui.AddButton("xm+15 y+10 w125 h30", "📄 Manifiesto").OnEvent("Click", (*) => CopyFile(RF["DOC_MANIFIESTO"]))
myGui.AddButton("x+10 w125 h30", "🏗️ Arquitectura").OnEvent("Click", (*) => CopyFile(RF["DOC_ARQUITECTURA"]))
myGui.AddButton("x+10 w125 h30", "⚙️ Reglas IA").OnEvent("Click", (*) => CopyFile(RF["DOC_NEXUS"]))

myGui.AddButton("xm+15 y+10 w125 h30", "📝 Editar Mem").OnEvent("Click", (*) => EditFile(RF["MEMORIA"]))
myGui.AddButton("x+10 w125 h30", "✏️ Editar Prompt").OnEvent("Click", (*) => EditFile(RF["PROMPT_MAESTRO"]))
myGui.AddButton("x+10 w125 h30", "📂 Docs Dir").OnEvent("Click", (*) => OpenPath(RF["DOCS"]))

; ===== BLOQUE 3: SISTEMA / CORE =====
myGui.AddGroupBox("xm y+15 w430 h150 c39FF14", " SISTEMA / CORE ")
myGui.AddButton("xm+15 yp+30 w125 h30", "🚀 ARRANCAR").OnEvent("Click", (*) => RunBat(RF["BAT_BOOT"]))
myGui.AddButton("x+10 w125 h30", "🛑 PARAR").OnEvent("Click", (*) => RunBat(RF["BAT_STOP"]))
myGui.AddButton("x+10 w125 h30", "🐙 GIT PUSH").OnEvent("Click", (*) => RunGitPush()) ; NUEVO BOTÓN GIT PUSH

myGui.AddButton("xm+15 y+10 w125 h30", "🔍 AUDITAR").OnEvent("Click", (*) => RunBat(RF["BAT_AUDIT"]))
myGui.AddButton("x+10 w125 h30", "⚡ RESET RAM").OnEvent("Click", (*) => RunBat(RF["BAT_RESET"]))
myGui.AddButton("x+10 w125 h30", "🖥️ Snippet PS").OnEvent("Click", CopySnippetPS)

; ===== BLOQUE 4: CÓDIGO / FRAMEWORKS =====
myGui.AddGroupBox("xm y+15 w430 h80 c39FF14", " CÓDIGO / FRAMEWORKS ")
myGui.AddButton("xm+15 yp+30 w125 h30", "📁 Root Core").OnEvent("Click", (*) => OpenPath(RF["ROOT"]))
myGui.AddButton("x+10 w125 h30", "🔎 Buscar Repo").OnEvent("Click", SearchInRepo)
myGui.AddButton("x+10 w125 h30", "🧱 Crear Módulo").OnEvent("Click", CreateModule)

; ===== PIE =====
myGui.AddButton("xm+155 y+15 w120 h32", "✖ CERRAR").OnEvent("Click", (*) => ExitApp())

; Ajuste de altura
myGui.Show("w455 h590")