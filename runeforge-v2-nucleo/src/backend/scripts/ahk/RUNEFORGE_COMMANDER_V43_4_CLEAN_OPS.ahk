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
    "TRACE", "C:\RUNEFOGE_PRO\runeforge\data\commander\commander-trace.jsonl",
    "LATEST", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.txt",
    "CLEAN", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.clean.txt",
    "SHELL", "C:\RUNEFOGE_PRO\runeforge\scripts\Start-Runeforge-Shell.ps1",
    "CAPTURE", "C:\RUNEFOGE_PRO\runeforge\scripts\Invoke-Runeforge-Capture.ps1"
)

global Main := ""
global Preview := ""
global SafeMode := ""

Q(s) {
    return Chr(34) . s . Chr(34)
}

Toast(msg, ms := 1800) {
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
        line := '{"ts":"' . EscapeJson(NowIso()) . '","action":"' . EscapeJson(action) . '","extra":"' . EscapeJson(extra) . '","source":"AHK_V43_4"}' . "`n"
        FileAppend(line, RF["TRACE"], "UTF-8")
    }
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
        A_Clipboard := txt
        ClipWait(1)
        Trace("COPY_CLEAN", "manual")
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

; ---------------------------------------------------------------------
; GUI
; ---------------------------------------------------------------------

Main := Gui("+AlwaysOnTop +ToolWindow", "RUNEFORGE V43.4 CLEAN OPS")
Main.BackColor := "101018"
Main.MarginX := 14
Main.MarginY := 12
Main.SetFont("s10 cF4EAFF", "Segoe UI")

Main.SetFont("s12 c39FF14 bold", "Consolas")
Main.Add("Text", "x14 y10 w780 h34 Center 0x200 Background000000", "ᚱ RUNEFORGE COMMANDER V43.4 // CLEAN OPS PANEL")

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y54 w380 h210", "CAPTURAS V43.3")
Main.SetFont("s9 cF4EAFF bold", "Segoe UI")

Main.Add("Button", "x30 y82 w164 h34", "Abrir Shell").OnEvent("Click", OpenShell)
Main.Add("Button", "x210 y82 w164 h34", "rf-status").OnEvent("Click", (*) => RunCapture("status"))

Main.Add("Button", "x30 y126 w164 h34", "Exports List").OnEvent("Click", (*) => RunCapture("exports-list"))
Main.Add("Button", "x210 y126 w164 h34", "Backend Root").OnEvent("Click", (*) => RunCapture("backend-root"))

Main.Add("Button", "x30 y170 w164 h34", "package.json").OnEvent("Click", (*) => RunCapture("package"))
Main.Add("Button", "x210 y170 w164 h34", "src tree").OnEvent("Click", (*) => RunCapture("src-tree"))

Main.Add("Button", "x30 y214 w164 h34", "PM2 + Health").OnEvent("Click", (*) => RunCapture("pm2-health"))
Main.Add("Button", "x210 y214 w164 h34", "Preparar V44").OnEvent("Click", PrepareV44)

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x414 y54 w380 h210", "ARCHIVOS / NAVEGACIÓN")
Main.SetFont("s9 cF4EAFF bold", "Segoe UI")

Main.Add("Button", "x430 y82 w164 h34", "Ver Clean").OnEvent("Click", OpenClean)
Main.Add("Button", "x610 y82 w164 h34", "Cargar Clean").OnEvent("Click", LoadClean)

Main.Add("Button", "x430 y126 w164 h34", "Copiar Clean").OnEvent("Click", CopyClean)
Main.Add("Button", "x610 y126 w164 h34", "Abrir Exports").OnEvent("Click", (*) => OpenPath(RF["EXPORTS"]))

Main.Add("Button", "x430 y170 w164 h34", "Abrir Backend").OnEvent("Click", (*) => OpenPath(RF["BACKEND"]))
Main.Add("Button", "x610 y170 w164 h34", "Abrir Docs").OnEvent("Click", (*) => OpenPath(RF["DOCS"]))

Main.Add("Button", "x430 y214 w164 h34", "Commander Data").OnEvent("Click", (*) => OpenPath(RF["COMMANDER"]))
Main.Add("Button", "x610 y214 w164 h34", "Trace JSONL").OnEvent("Click", (*) => OpenPath(RF["TRACE"]))

SafeMode := Main.Add("Checkbox", "x30 y274 w260 h24 Checked", "Modo seguro: sin ejecución destructiva")
Main.SetFont("s8 c888888", "Segoe UI")
Main.Add("Text", "x310 y276 w460 h22", "Regla: no lee .env, no copia automático, no toca backend.")

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y308 w780 h310", "LATEST CLEAN / PREVIEW")
Main.SetFont("s9 cF4EAFF", "Consolas")
Preview := Main.Add("Edit", "x30 y334 w748 h230 Multi WantTab -Wrap")

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("Text", "x30 y574 w540 h24", "Hotkeys: Ctrl+Alt+P mostrar/ocultar | Ctrl+Alt+S abrir shell | Ctrl+Alt+V preparar V44")
Main.SetFont("s9 cFF4D6D bold", "Segoe UI")
Main.Add("Button", "x658 y570 w120 h30", "Cerrar").OnEvent("Click", (*) => ExitApp())

Main.OnEvent("Close", (*) => ExitApp())
Main.Show("w810 h638")

LoadClean()

^!p:: {
    global Main
    try {
        if WinActive("RUNEFORGE V43.4") {
            Main.Hide()
        } else {
            Main.Show()
            WinActivate("RUNEFORGE V43.4")
        }
    }
}

^!s::OpenShell()
^!v::PrepareV44()
