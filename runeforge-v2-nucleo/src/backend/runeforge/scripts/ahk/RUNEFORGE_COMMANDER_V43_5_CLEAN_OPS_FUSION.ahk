#Requires AutoHotkey v2.0
#SingleInstance Force

if not A_IsAdmin {
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

global RF := Map(
    "ROOT", "C:\RUNEFOGE_PRO\runeforge",
    "BACKEND", "C:\RUNEFOGE_PRO\runeforge\app",
    "DOCS", "C:\RUNEFOGE_PRO\runeforge\docs",
    "COMMANDER", "C:\RUNEFOGE_PRO\runeforge\data\commander",
    "EXPORTS", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports",
    "SNIPPETS", "C:\RUNEFOGE_PRO\runeforge\data\commander\snippets",
    "TRACE", "C:\RUNEFOGE_PRO\runeforge\data\commander\commander-trace.jsonl",
    "LATEST", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.txt",
    "CLEAN", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.clean.txt",
    "SHELL", "C:\RUNEFOGE_PRO\runeforge\scripts\Start-Runeforge-Shell.ps1",
    "CAPTURE", "C:\RUNEFOGE_PRO\runeforge\scripts\Invoke-Runeforge-Capture.ps1"
)

global Main := ""
global Preview := ""
global SafeMode := ""
global PromptList := ""
global TargetHwnd := 0

SetTimer(TrackActiveWindow, 250)

TrackActiveWindow() {
    global TargetHwnd
    try {
        hwnd := WinGetID("A")
        title := WinGetTitle("ahk_id " hwnd)
        if (!InStr(title, "RUNEFORGE V43.5")) {
            TargetHwnd := hwnd
        }
    }
}

Q(s) {
    return Chr(34) . s . Chr(34)
}

Toast(msg, ms := 1600) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -ms)
}

NowIso() {
    return FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
}

EscapeJson(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '"', '\"')
    s := StrReplace(s, "`r", "\r")
    s := StrReplace(s, "`n", "\n")
    return s
}

Trace(action, extra := "") {
    global RF
    try {
        line := '{"ts":"' . EscapeJson(NowIso()) . '","action":"' . EscapeJson(action) . '","extra":"' . EscapeJson(extra) . '","source":"AHK_V43_5"}' . "`n"
        FileAppend(line, RF["TRACE"], "UTF-8")
    }
}

SetClip(text, label := "payload") {
    A_Clipboard := text
    ClipWait(1)
    Trace("CLIPBOARD_SET", label . " len=" . StrLen(text))
}

SendTarget(keys, label := "") {
    global TargetHwnd

    if (TargetHwnd) {
        try {
            WinActivate("ahk_id " TargetHwnd)
            Sleep(120)
        }
    }

    Send(keys)
    Trace("SEND_TARGET", label . " keys=" . keys)
}

PasteText(text, label := "payload", sendEnter := false) {
    global TargetHwnd

    SetClip(text, label)

    if (TargetHwnd) {
        try {
            WinActivate("ahk_id " TargetHwnd)
            Sleep(140)
        }
    }

    Send("^v")
    Sleep(90)

    if (sendEnter) {
        Send("{Enter}")
    }

    Trace("PASTE_TEXT", label . " enter=" . sendEnter)
}

OpenPath(path) {
    if FileExist(path) {
        Run(path)
        Trace("OPEN_PATH", path)
    } else {
        Toast("No existe ruta")
        Trace("OPEN_PATH_MISSING", path)
    }
}

OpenShell(*) {
    global RF
    cmd := "pwsh.exe -NoLogo -NoExit -ExecutionPolicy Bypass -File " . Q(RF["SHELL"])
    Run(cmd, RF["ROOT"])
    Trace("OPEN_SHELL", RF["SHELL"])
    Toast("Runeforge Shell abierto")
}

RunCapture(preset) {
    global RF, Preview
    cmd := "pwsh.exe -NoLogo -ExecutionPolicy Bypass -File " . Q(RF["CAPTURE"]) . " -Preset " . Q(preset)
    RunWait(cmd, RF["ROOT"], "Hide")
    Trace("CAPTURE", preset)
    Toast("Captura lista: " . preset)
    LoadClean()
}

LoadClean(*) {
    global RF, Preview

    if FileExist(RF["CLEAN"]) {
        try {
            txt := FileRead(RF["CLEAN"], "UTF-8")
            Preview.Value := txt
            Trace("LOAD_CLEAN", RF["CLEAN"])
        } catch as err {
            Preview.Value := "ERROR leyendo clean: " . err.Message
        }
    } else {
        Preview.Value := "PENDIENTE: no existe latest-terminal-export.clean.txt"
    }
}

CopyClean(*) {
    global RF

    if FileExist(RF["CLEAN"]) {
        txt := FileRead(RF["CLEAN"], "UTF-8")
        SetClip(txt, "LATEST_CLEAN_MANUAL")
        Toast("Clean copiado manualmente")
    } else {
        Toast("No existe clean")
    }
}

OpenClean(*) {
    global RF
    OpenPath(RF["CLEAN"])
}

PrepareV44(*) {
    RunCapture("v44-preflight")
}

ReadPrompt(name) {
    global RF

    if (name = "V44 Preflight") {
        return FileRead(RF["SNIPPETS"] . "\prompt_v44_preflight_analysis.txt", "UTF-8")
    }

    if (name = "Security Review") {
        return FileRead(RF["SNIPPETS"] . "\prompt_security_review.txt", "UTF-8")
    }

    if (name = "Memory Update") {
        return FileRead(RF["SNIPPETS"] . "\prompt_memory_update.txt", "UTF-8")
    }

    if (name = "Analyze Latest Clean") {
        prompt := FileRead(RF["SNIPPETS"] . "\prompt_analyze_latest_clean.txt", "UTF-8")
        clean := ""
        if FileExist(RF["CLEAN"]) {
            clean := FileRead(RF["CLEAN"], "UTF-8")
        } else {
            clean := "PENDIENTE: latest clean no existe."
        }
        return prompt . "`r`n`r`n--- LATEST CLEAN ---`r`n" . clean
    }

    return "PENDIENTE: prompt no encontrado."
}

LoadPrompt(*) {
    global PromptList, Preview
    name := PromptList.Text
    payload := ReadPrompt(name)
    Preview.Value := payload
    Trace("LOAD_PROMPT", name)
}

CopyPrompt(*) {
    global PromptList
    name := PromptList.Text
    payload := ReadPrompt(name)
    SetClip(payload, "PROMPT_" . name)
    Toast("Prompt copiado: " . name)
}

PastePrompt(*) {
    global PromptList, SafeMode, Preview
    name := PromptList.Text
    payload := ReadPrompt(name)
    Preview.Value := payload

    if (SafeMode.Value) {
        SetClip(payload, "PROMPT_" . name)
        Toast("Modo seguro: prompt copiado")
        return
    }

    PasteText(payload, "PROMPT_" . name, false)
    Toast("Prompt pegado")
}

ExecutePrompt(*) {
    global PromptList, SafeMode, Preview
    name := PromptList.Text
    payload := ReadPrompt(name)
    Preview.Value := payload

    if (SafeMode.Value) {
        SetClip(payload, "PROMPT_" . name)
        Toast("Modo seguro: copiado, no ejecutado")
        return
    }

    result := MsgBox("Esto pegará el prompt y enviará ENTER.`n`n¿Continuar?", "Runeforge Prompt Execute", "YesNo Icon!")
    if (result != "Yes") {
        Toast("Cancelado")
        return
    }

    PasteText(payload, "PROMPT_EXEC_" . name, true)
    Toast("Prompt ejecutado")
}

CopyPreview(*) {
    global Preview
    SetClip(Preview.Value, "PREVIEW")
    Toast("Preview copiado")
}

PastePreview(*) {
    global Preview, SafeMode

    if (SafeMode.Value) {
        SetClip(Preview.Value, "PREVIEW_SAFE")
        Toast("Modo seguro: preview copiado")
        return
    }

    PasteText(Preview.Value, "PREVIEW", false)
}

; ---------------------------------------------------------------------
; GUI
; ---------------------------------------------------------------------

Main := Gui("+AlwaysOnTop +ToolWindow", "RUNEFORGE V43.5 CLEAN OPS FUSION")
Main.BackColor := "161A22"
Main.MarginX := 14
Main.MarginY := 10
Main.SetFont("s10 cF4EAFF", "Segoe UI")

Main.SetFont("s12 c39FF14 bold", "Segoe UI")
Main.Add("Text", "x14 y8 w900 h32 Center 0x200 Background000000", "🚀 RUNEFORGE COMMANDER V43.5 // CLEAN OPS FUSION PANEL")

; FAST INPUT
Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y48 w900 h82", "⚡ ACCIONES RÁPIDAS / MULTIMEDIA")
Main.SetFont("s9 cF4EAFF bold", "Segoe UI")

Main.Add("Button", "x30 y72 w82 h30", "📋 Copiar").OnEvent("Click", (*) => SendTarget("^c", "copy"))
Main.Add("Button", "x118 y72 w82 h30", "📌 Pegar").OnEvent("Click", (*) => SendTarget("^v", "paste"))
Main.Add("Button", "x206 y72 w82 h30", "↩ Enter").OnEvent("Click", (*) => SendTarget("{Enter}", "enter"))
Main.Add("Button", "x294 y72 w116 h30", "📌↩ Pegar+Enter").OnEvent("Click", (*) => (SendTarget("^v", "paste"), Sleep(80), SendTarget("{Enter}", "enter")))
Main.Add("Button", "x418 y72 w82 h30", "⌨ Ctrl+C").OnEvent("Click", (*) => SendTarget("^c", "ctrl_c"))
Main.Add("Button", "x506 y72 w64 h30", "⛔ Esc").OnEvent("Click", (*) => SendTarget("{Esc}", "esc"))

Main.Add("Button", "x576 y72 w64 h30", "🔄 F5").OnEvent("Click", (*) => SendTarget("{F5}", "f5"))
Main.Add("Button", "x646 y72 w88 h30", "↻ Ctrl+R").OnEvent("Click", (*) => SendTarget("^r", "ctrl_r"))

Main.Add("Button", "x742 y72 w58 h30", "🔉").OnEvent("Click", (*) => Send("{Volume_Down 2}"))
Main.Add("Button", "x806 y72 w58 h30", "🔊").OnEvent("Click", (*) => Send("{Volume_Up 2}"))
Main.Add("Button", "x870 y72 w58 h30", "🔇").OnEvent("Click", (*) => Send("{Volume_Mute}"))
Main.Add("Button", "x934 y72 w36 h30", "⏯").OnEvent("Click", (*) => Send("{Media_Play_Pause}"))

Main.Add("Button", "x30 y104 w122 h24", "✂ Snapshot").OnEvent("Click", (*) => Send("#+s"))
Main.Add("Button", "x164 y104 w112 h24", "🏠 Home").OnEvent("Click", (*) => SendTarget("{Home}", "home"))
Main.Add("Button", "x288 y104 w112 h24", "🔚 End").OnEvent("Click", (*) => SendTarget("{End}", "end"))

SafeMode := Main.Add("Checkbox", "x420 y106 w290 h22 Checked", "🛡️ Modo seguro: prompts solo copian")
Main.SetFont("s8 c888888", "Segoe UI")
Main.Add("Text", "x710 y108 w210 h20", "🔒 No toca backend / no lee .env")

; CAPTURES
Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y140 w440 h190", "🧪 CAPTURAS V43.3 / PREFLIGHT V44")
Main.SetFont("s9 cF4EAFF bold", "Segoe UI")

Main.Add("Button", "x30 y166 w128 h30", "🖥 Abrir Shell").OnEvent("Click", OpenShell)
Main.Add("Button", "x166 y166 w128 h30", "📊 rf-status").OnEvent("Click", (*) => RunCapture("status"))
Main.Add("Button", "x302 y166 w128 h30", "📦 Exports").OnEvent("Click", (*) => RunCapture("exports-list"))

Main.Add("Button", "x30 y204 w128 h30", "🧩 Backend").OnEvent("Click", (*) => RunCapture("backend-root"))
Main.Add("Button", "x166 y204 w128 h30", "📄 package.json").OnEvent("Click", (*) => RunCapture("package"))
Main.Add("Button", "x302 y204 w128 h30", "🌳 src tree").OnEvent("Click", (*) => RunCapture("src-tree"))

Main.Add("Button", "x30 y242 w128 h30", "❤️ PM2 + Health").OnEvent("Click", (*) => RunCapture("pm2-health"))
Main.Add("Button", "x166 y242 w128 h30", "🚀 Preparar V44").OnEvent("Click", PrepareV44)
Main.Add("Button", "x302 y242 w128 h30", "🔄 Cargar Clean").OnEvent("Click", LoadClean)

Main.Add("Button", "x30 y280 w128 h30", "📋 Copiar Clean").OnEvent("Click", CopyClean)
Main.Add("Button", "x166 y280 w128 h30", "👁 Ver Clean").OnEvent("Click", OpenClean)
Main.Add("Button", "x302 y280 w128 h30", "📂 Abrir Exports").OnEvent("Click", (*) => OpenPath(RF["EXPORTS"]))

; PROMPTS
Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x474 y140 w440 h190", "💬 PROMPTS / EJECUCIÓN")
Main.SetFont("s9 cF4EAFF", "Segoe UI")

PromptList := Main.Add("DropDownList", "x490 y166 w404", ["V44 Preflight", "Security Review", "Memory Update", "Analyze Latest Clean"])
PromptList.Choose(1)

Main.SetFont("s9 cF4EAFF bold", "Segoe UI")
Main.Add("Button", "x490 y204 w124 h30", "📥 Cargar Prompt").OnEvent("Click", LoadPrompt)
Main.Add("Button", "x630 y204 w124 h30", "📋 Copiar Prompt").OnEvent("Click", CopyPrompt)
Main.Add("Button", "x770 y204 w124 h30", "📌 Pegar Prompt").OnEvent("Click", PastePrompt)

Main.Add("Button", "x490 y242 w180 h34", "▶ Ejecutar Prompt").OnEvent("Click", ExecutePrompt)
Main.Add("Button", "x686 y242 w98 h34", "📋 Preview").OnEvent("Click", CopyPreview)
Main.Add("Button", "x796 y242 w98 h34", "📌 Preview").OnEvent("Click", PastePreview)

Main.Add("Button", "x490 y286 w124 h30", "🧩 Backend").OnEvent("Click", (*) => OpenPath(RF["BACKEND"]))
Main.Add("Button", "x630 y286 w124 h30", "📚 Docs").OnEvent("Click", (*) => OpenPath(RF["DOCS"]))
Main.Add("Button", "x770 y286 w124 h30", "🧾 Trace").OnEvent("Click", (*) => OpenPath(RF["TRACE"]))

; PREVIEW
Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y342 w900 h330", "📋 ÚLTIMO CLEAN / VISTA PREVIA")
Main.SetFont("s9 cF4EAFF", "Consolas")
Preview := Main.Add("Edit", "x30 y368 w868 h240 Multi WantTab -Wrap Background202633 cF7F9FC")
Preview.SetFont("s10 cF7F9FC", "Consolas")

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("Text", "x30 y620 w700 h24", "⌨ Atajos: Ctrl+Alt+P panel | Ctrl+Alt+S shell | Ctrl+Alt+V V44 | Ctrl+Alt+C copiar clean")
Main.SetFont("s9 cFF4D6D bold", "Segoe UI")
Main.Add("Button", "x778 y616 w120 h30", "✖ Cerrar").OnEvent("Click", (*) => ExitApp())

Main.OnEvent("Close", (*) => ExitApp())
Main.Show("w930 h690")

LoadClean()

^!p:: {
    global Main
    try {
        if WinActive("RUNEFORGE V43.5") {
            Main.Hide()
        } else {
            Main.Show()
            WinActivate("RUNEFORGE V43.5")
        }
    }
}

^!s::OpenShell()
^!v::PrepareV44()
^!c::CopyClean()


