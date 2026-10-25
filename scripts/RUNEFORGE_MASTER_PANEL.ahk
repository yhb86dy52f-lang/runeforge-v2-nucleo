; ================================
; RUNEFORGE MASTER PANEL V21.1
; Interfaz Completa + Consola de Eventos (Sintaxis Corregida)
; ================================
#Requires AutoHotkey v2.0
#SingleInstance Force

global RF := Map(
    "ROOT", "C:\RUNEFORGE_V2_CORE",
    "SCRIPTS", "C:\RUNEFORGE_V2_CORE\scripts",
    "DOCS", "C:\RUNEFORGE_V2_CORE\docs\md",
    "DATA", "C:\RUNEFORGE_V2_CORE\core_data",
    "MEMORIA", "C:\RUNEFORGE_V2_CORE\core_data\memorias\memoria_operativa.txt",
    "PROMPT_MAESTRO", "C:\RUNEFORGE_V2_CORE\core_data\prompts\prompt_maestro.txt",
    "DOC_MANIFIESTO", "C:\RUNEFORGE_V2_CORE\docs\md\MANIFIESTO.md",
    "DOC_ARQUITECTURA", "C:\RUNEFORGE_V2_CORE\docs\md\RUNEFORGE_V2_CORE.md",
    "DOC_NEXUS", "C:\RUNEFORGE_V2_CORE\docs\md\NEXUS_ARCHITECT_AUTOMATION.md",
    "LOGDIR", "C:\RUNEFORGE_V2_CORE\logs",
    "LOGFILE", "C:\RUNEFORGE_V2_CORE\logs\panel.log"
)

global CYBER_MONJA_GUID := "{9f2b7a50-7c7e-4a35-9a6e-000000000001}"
global txtTime, txtCpu, txtRam, txtFastify, txtWhisper, txtOllama, txtTauri, txtTailscale, txtConsole, ScriptBox

; --- Utilidades ---
LogConsole(msg) {
    global txtConsole, RF
    if IsSet(txtConsole) && IsObject(txtConsole) {
        timestamp := FormatTime(A_Now, "HH:mm:ss")
        current := txtConsole.Value
        lines := StrSplit(current, "`n")
        if (lines.Length > 3)
            current := lines[lines.Length-2] "`n" lines[lines.Length-1] "`n"
        txtConsole.Value := current "[" timestamp "] " msg "`n"
    }
    try FileAppend "[" FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "] " msg "`n", RF["LOGFILE"], "UTF-8"
}

CopyToClipboard(text, successMsg) {
    try {
        A_Clipboard := text
        LogConsole(successMsg)
    }
}

RunInWT(cmd) {
    global CYBER_MONJA_GUID
    try Run('wt.exe -w 0 -p "' CYBER_MONJA_GUID '" ' cmd)
}

; --- Telemetría ---
UpdateDashboard() {
    global txtTime, txtCpu, txtRam, txtFastify, txtWhisper, txtOllama, txtTauri, txtTailscale
    txtTime.Text := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    txtFastify.Text := "Fastify: " (ProcessExist("node.exe") ? "🟢" : "🔴")
    txtWhisper.Text := "Whisper: " (ProcessExist("python.exe") ? "🟢" : "🔴")
    txtOllama.Text  := "Ollama:  " (ProcessExist("ollama.exe") ? "🟢" : "🔴")
    txtTauri.Text   := "Tauri:   " (ProcessExist("app.exe") ? "🟢" : "🔴")
    txtTailscale.Text := "Tailscale: " (ProcessExist("tailscaled.exe") ? "🟢" : "🔴")

    try {
        wmi := ComObjGet("winmgmts:\\.\root\cimv2")
        cpu := wmi.ExecQuery("SELECT LoadPercentage FROM Win32_Processor").ItemIndex(0).LoadPercentage
        os := wmi.ExecQuery("SELECT FreePhysicalMemory, TotalVisibleMemorySize FROM Win32_OperatingSystem").ItemIndex(0)
        ramUsed := (os.TotalVisibleMemorySize - os.FreePhysicalMemory) / 1024 / 1024
        txtCpu.Text := "CPU: " cpu "%"
        txtRam.Text := "RAM: " Format("{:.1f}", ramUsed) " GB"
    } catch {
    }
}

; --- Acciones ---
ActUpdate() {
    UpdateDashboard()
    LogConsole("Datos actualizados manualmente.")
}

ActDashboard() {
    Run("https://yhb86dy52f-lang.github.io/runeforge-v2-nucleo/")
    LogConsole("Abriendo Dashboard PWA.")
}

ActFlota() {
    Run("https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo/tree/main/FlotaKW_Completo_v3.2_SOBERANO")
    LogConsole("Abriendo FlotaKW.")
}

ActMemoria() {
    CopyToClipboard(FileRead(RF["MEMORIA"], "UTF-8"), "Memoria copiada.")
}

ActPrompt() {
    CopyToClipboard(FileRead(RF["PROMPT_MAESTRO"], "UTF-8"), "Prompt copiado.")
}

ActManifiesto() {
    CopyToClipboard(FileRead(RF["DOC_MANIFIESTO"], "UTF-8"), "Manifiesto copiado.")
}

ActArquitectura() {
    CopyToClipboard(FileRead(RF["DOC_ARQUITECTURA"], "UTF-8"), "Arquitectura copiada.")
}

ActReglasIA() {
    CopyToClipboard(FileRead(RF["DOC_NEXUS"], "UTF-8"), "Reglas IA copiadas.")
}

ActEditarMem() {
    Run('notepad.exe "' RF["MEMORIA"] '"')
    LogConsole("Abriendo editor de Memoria.")
}

ActEditarPrompt() {
    Run('notepad.exe "' RF["PROMPT_MAESTRO"] '"')
    LogConsole("Abriendo editor de Prompt.")
}

ActDocs() {
    Run(RF["DOCS"])
    LogConsole("Abriendo carpeta Docs.")
}

ActArrancar() {
    RunInWT('cmd.exe /c "C:\RUNEFORGE_V2_CORE\scripts\RUNEFORGE.bat"')
    LogConsole("Iniciando Ecosistema Global...")
}

ActParar() {
    RunInWT('cmd.exe /c "C:\RUNEFORGE_V2_CORE\scripts\STOP.bat"')
    LogConsole("Ejecutando Apagón Nuclear...")
}

ActGitPush() {
    global CYBER_MONJA_GUID
    try {
        ; Aplicando Regla de AHK v2
        Run('wt.exe -w 0 -p "' CYBER_MONJA_GUID '" pwsh -NoExit -ExecutionPolicy Bypass -File "C:\RUNEFORGE_V2_CORE\scripts\rf-git.ps1"')
        LogConsole("Sincronizando con GitHub...")
    } catch as e {
        ; Captura de error moderna v2
        LogConsole("❌ Error al abrir Terminal: " e.Message)
    }
}

ActAuditar() {
    RunInWT('pwsh -NoExit -File "C:\RUNEFORGE_V2_CORE\scripts\AUDIT.ps1"')
    LogConsole("Ejecutando Auditoría...")
}

ActResetRam() {
    RunInWT('pwsh -NoExit -File "C:\RUNEFORGE_V2_CORE\scripts\Optimizador-Runeforge.ps1"')
    LogConsole("Ejecutando Reset de RAM...")
}

ActCopiarLog() {
    if FileExist(RF["LOGFILE"]) {
        CopyToClipboard(FileRead(RF["LOGFILE"], "UTF-8"), "Log completo copiado.")
    } else {
        LogConsole("El log está vacío.")
    }
}

ActEjecutarScratchpad() {
    global ScriptBox, RF
    scriptText := ScriptBox.Text
    if (Trim(scriptText) = "") {
        LogConsole("Error: El Scratchpad está vacío.")
        return
    }
    tmpFile := RF["SCRIPTS"] "\scratch_ia.ps1"
    FileDelete tmpFile
    wrapper := "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`n"
    wrapper .= "$tempLog = `"$env:TEMP\scratch_output.txt`"`n"
    wrapper .= "Start-Transcript -Path `$tempLog -Force | Out-Null`n"
    wrapper .= "try {`n`n" scriptText "`n} catch { `$_ } finally {`n"
    wrapper .= "    Stop-Transcript | Out-Null`n"
    wrapper .= "    if (Test-Path `$tempLog) { Get-Content `$tempLog -Raw | Set-Clipboard }`n}`n"
    FileAppend wrapper, tmpFile, "UTF-8"
    RunInWT('pwsh.exe -NoExit -ExecutionPolicy Bypass -File "' tmpFile '"')
    LogConsole("Ejecutando Scratchpad en Terminal...")
}

ActCopiarTexto() {
    global ScriptBox
    if (Trim(ScriptBox.Text) != "") {
        A_Clipboard := ScriptBox.Text
        LogConsole("Texto del Scratchpad copiado.")
    }
}

ActLimpiar() {
    global ScriptBox
    ScriptBox.Text := ""
    LogConsole("Scratchpad limpiado.")
}

; --- GUI ---
myGui := Gui("+AlwaysOnTop -MaximizeBox", "RUNEFORGE COMMAND CENTER V21.1")
myGui.BackColor := "0D0211"
myGui.SetFont("s10 c39FF14 Bold", "Segoe UI")

myGui.SetFont("s16 Bold c39FF14", "Segoe UI")
myGui.AddText("xm w510 Center", "⚡ RUNEFORGE COMMAND CENTER")
myGui.SetFont("s9 c00FFFF", "Consolas")
myGui.AddText("xm w510 Center", "======================================================")

myGui.SetFont("s10 c39FF14 Bold", "Segoe UI")
txtTime := myGui.AddText("xm w170", "Cargando...")
txtCpu  := myGui.AddText("x+10 w100", "CPU: --%")
txtRam  := myGui.AddText("x+10 w100", "RAM: -- GB")
myGui.AddText("xm w510 Center", "======================================================")

myGui.AddGroupBox("xm y+10 w510 h60 c39FF14", " STATUS TÁCTICO ")
txtFastify := myGui.AddText("xm+15 yp+25 w100", "Fastify: 🔴")
txtWhisper := myGui.AddText("x+5 w100", "Whisper: 🔴")
txtOllama  := myGui.AddText("x+5 w100", "Ollama: 🔴")
txtTauri   := myGui.AddText("x+5 w100", "Tauri: 🔴")
txtTailscale := myGui.AddText("x+5 w100", "Tailscale: 🔴")

myGui.AddGroupBox("xm y+15 w510 h110 c39FF14", " MASTERS & MÓDULOS ")
myGui.SetFont("s9 c39FF14", "Segoe UI")
myGui.AddButton("xm+15 yp+25 w110 h32 +Background1A0B1F", "📊 Dashboard").OnEvent("Click", (*) => ActDashboard())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "🚀 FlotaKW").OnEvent("Click", (*) => ActFlota())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "🧠 Memoria Ops").OnEvent("Click", (*) => ActMemoria())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "📜 Prompt Master").OnEvent("Click", (*) => ActPrompt())
myGui.AddButton("xm+15 y+10 w110 h32 +Background1A0B1F", "📄 Manifiesto").OnEvent("Click", (*) => ActManifiesto())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "🏗️ Arquitectura").OnEvent("Click", (*) => ActArquitectura())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "⚙️ Reglas IA").OnEvent("Click", (*) => ActReglasIA())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "📝 Editar Mem").OnEvent("Click", (*) => ActEditarMem())

myGui.AddGroupBox("xm y+15 w510 h110 c39FF14", " SISTEMA / CORE ")
myGui.AddButton("xm+15 yp+25 w110 h32 +Background1A0B1F", "🚀 ARRANCAR").OnEvent("Click", (*) => ActArrancar())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "🛑 PARAR").OnEvent("Click", (*) => ActParar())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "🐙 GIT PUSH").OnEvent("Click", (*) => ActGitPush())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "🔍 AUDITAR").OnEvent("Click", (*) => ActAuditar())
myGui.AddButton("xm+15 y+10 w110 h32 +Background1A0B1F", "⚡ RESET RAM").OnEvent("Click", (*) => ActResetRam())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "🔄 ACTUALIZAR").OnEvent("Click", (*) => ActUpdate())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "📋 COPIAR LOG").OnEvent("Click", (*) => ActCopiarLog())
myGui.AddButton("x+10 w110 h32 +Background1A0B1F", "📂 Docs Dir").OnEvent("Click", (*) => ActDocs())

myGui.AddGroupBox("xm y+15 w510 h80 c39FF14", " CONSOLA DE EVENTOS ")
myGui.SetFont("s9 c00FFFF", "Consolas")
txtConsole := myGui.AddEdit("xm+15 yp+25 w480 h45 ReadOnly Background080A12 c00FFFF -VScroll", "Sistema listo...`n")

myGui.AddGroupBox("xm y+15 w510 h180 c39FF14", " SCRATCHPAD (Ejecución IA) ")
myGui.SetFont("s10 cWhite", "Consolas")
ScriptBox := myGui.AddEdit("xm+15 yp+25 w480 h120 Multi Background1A0B1F c39FF14", "")
myGui.SetFont("s9 c39FF14", "Segoe UI")
myGui.AddButton("xm+15 y+10 w155 h30 +Background1A0B1F", "▶ EJECUTAR").OnEvent("Click", (*) => ActEjecutarScratchpad())
myGui.AddButton("x+10 w155 h30 +Background1A0B1F", "📋 COPIAR TEXTO").OnEvent("Click", (*) => ActCopiarTexto())
myGui.AddButton("x+10 w155 h30 +Background1A0B1F", "🧹 LIMPIAR").OnEvent("Click", (*) => ActLimpiar())

myGui.AddButton("xm+195 y+20 w120 h32 +Background1A0B1F", "✖ CERRAR").OnEvent("Click", (*) => ExitApp())

myGui.Show("w540 h850")
UpdateDashboard()
SetTimer(UpdateDashboard, 5000)
LogConsole("Panel V21.1 iniciado correctamente.")