#Requires AutoHotkey v2.0
#SingleInstance Force

if not A_IsAdmin {
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

global RF := Map(
    "ROOT", "C:\RUNEFOGE_PRO\runeforge",
    "FULL", "C:\RUNEFOGE_PRO\runeforge\scripts\ahk\RUNEFORGE_COMMANDER_V43_5_CLEAN_OPS_FUSION.ahk",
    "LAUNCHER", "C:\RUNEFOGE_PRO\runeforge\scripts\Start-Runeforge-Panel.ps1",
    "SHELL", "C:\RUNEFOGE_PRO\runeforge\scripts\Start-Runeforge-Shell.ps1",
    "CAPTURE", "C:\RUNEFOGE_PRO\runeforge\scripts\Invoke-Runeforge-Capture.ps1",
    "EXPORTS", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports",
    "CLEAN", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.clean.txt",
    "TRACE", "C:\RUNEFOGE_PRO\runeforge\data\commander\commander-trace.jsonl"
)

global Main := ""
global TargetHwnd := 0

SetTimer(TrackActiveWindow, 300)

TrackActiveWindow() {
    global TargetHwnd
    try {
        hwnd := WinGetID("A")
        title := WinGetTitle("ahk_id " hwnd)
        if (!InStr(title, "RUNEFORGE QUICK DOCK")) {
            TargetHwnd := hwnd
        }
    } catch {
    }
}

Q(s) {
    return Chr(34) . s . Chr(34)
}

Toast(msg, ms := 1400) {
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
        line := '{"ts":"' . EscapeJson(NowIso()) . '","action":"' . EscapeJson(action) . '","extra":"' . EscapeJson(extra) . '","source":"AHK_V43_6_QUICK_DOCK"}' . "`n"
        FileAppend(line, RF["TRACE"], "UTF-8")
    } catch {
    }
}

SendTarget(keys, label := "") {
    global TargetHwnd
    if (TargetHwnd) {
        try {
            WinActivate("ahk_id " TargetHwnd)
            Sleep(100)
        } catch {
        }
    }
    Send(keys)
    Trace("SEND_TARGET", label)
}

OpenPath(path) {
    if FileExist(path) {
        Run(path)
        Trace("OPEN_PATH", path)
    } else {
        Toast("No existe ruta")
    }
}

OpenShell(*) {
    global RF
    cmd := "pwsh.exe -NoLogo -NoExit -ExecutionPolicy Bypass -File " . Q(RF["SHELL"])
    Run(cmd, RF["ROOT"])
    Trace("OPEN_SHELL", "")
    Toast("Shell abierto")
}

RunCapture(preset) {
    global RF
    cmd := "pwsh.exe -NoLogo -ExecutionPolicy Bypass -File " . Q(RF["CAPTURE"]) . " -Preset " . Q(preset)
    RunWait(cmd, RF["ROOT"], "Hide")
    Trace("CAPTURE", preset)
    Toast("Captura: " . preset)
}

CopyClean(*) {
    global RF
    if FileExist(RF["CLEAN"]) {
        A_Clipboard := FileRead(RF["CLEAN"], "UTF-8")
        ClipWait(1)
        Trace("COPY_CLEAN", "manual")
        Toast("Clean copiado")
    } else {
        Toast("No existe clean")
    }
}

OpenClean(*) {
    global RF
    OpenPath(RF["CLEAN"])
}

OpenFull(*) {
    global RF
    cmd := "pwsh.exe -NoLogo -ExecutionPolicy Bypass -File " . Q(RF["LAUNCHER"]) . " -Mode Full"
    Run(cmd, RF["ROOT"])
    Trace("OPEN_FULL_PANEL", "")
    Toast("Panel maestro")
}

RestartQuick(*) {
    global RF
    cmd := "pwsh.exe -NoLogo -ExecutionPolicy Bypass -File " . Q(RF["LAUNCHER"]) . " -Mode Quick"
    Run(cmd, RF["ROOT"])
    Trace("RESTART_QUICK", "")
    ExitApp
}

Main := Gui("+AlwaysOnTop +ToolWindow", "RUNEFORGE QUICK DOCK V43.6")
Main.BackColor := "161A22"
Main.MarginX := 10
Main.MarginY := 8
Main.SetFont("s10 cF7F9FC bold", "Segoe UI")

Main.Add("Text", "x10 y8 w520 h28 Center 0x200 Background000000 c39FF14", "⚡ RUNEFORGE QUICK DOCK V43.6")

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x10 y44 w520 h76", "ACCIONES RÁPIDAS")
Main.SetFont("s9 cF7F9FC bold", "Segoe UI")

Main.Add("Button", "x24 y68 w72 h28", "📋 Copy").OnEvent("Click", (*) => SendTarget("^c", "copy"))
Main.Add("Button", "x102 y68 w72 h28", "📌 Paste").OnEvent("Click", (*) => SendTarget("^v", "paste"))
Main.Add("Button", "x180 y68 w72 h28", "↩ Enter").OnEvent("Click", (*) => SendTarget("{Enter}", "enter"))
Main.Add("Button", "x258 y68 w96 h28", "📌↩ P+Enter").OnEvent("Click", (*) => (SendTarget("^v", "paste"), Sleep(70), SendTarget("{Enter}", "enter")))
Main.Add("Button", "x360 y68 w56 h28", "Esc").OnEvent("Click", (*) => SendTarget("{Esc}", "esc"))
Main.Add("Button", "x422 y68 w42 h28", "F5").OnEvent("Click", (*) => SendTarget("{F5}", "f5"))
Main.Add("Button", "x470 y68 w46 h28", "CtrlR").OnEvent("Click", (*) => SendTarget("^r", "ctrl_r"))

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x10 y128 w520 h76", "MULTIMEDIA / VENTANA")
Main.SetFont("s9 cF7F9FC bold", "Segoe UI")

Main.Add("Button", "x24 y152 w64 h28", "🔉").OnEvent("Click", (*) => Send("{Volume_Down 2}"))
Main.Add("Button", "x94 y152 w64 h28", "🔊").OnEvent("Click", (*) => Send("{Volume_Up 2}"))
Main.Add("Button", "x164 y152 w64 h28", "🔇").OnEvent("Click", (*) => Send("{Volume_Mute}"))
Main.Add("Button", "x234 y152 w64 h28", "⏯").OnEvent("Click", (*) => Send("{Media_Play_Pause}"))
Main.Add("Button", "x304 y152 w86 h28", "✂ Shot").OnEvent("Click", (*) => Send("#+s"))
Main.Add("Button", "x396 y152 w56 h28", "Home").OnEvent("Click", (*) => SendTarget("{Home}", "home"))
Main.Add("Button", "x458 y152 w56 h28", "End").OnEvent("Click", (*) => SendTarget("{End}", "end"))

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("GroupBox", "x10 y212 w520 h100", "RUNEFORGE")
Main.SetFont("s9 cF7F9FC bold", "Segoe UI")

Main.Add("Button", "x24 y236 w86 h30", "🖥 Shell").OnEvent("Click", OpenShell)
Main.Add("Button", "x116 y236 w86 h30", "📊 Status").OnEvent("Click", (*) => RunCapture("status"))
Main.Add("Button", "x208 y236 w86 h30", "📋 Clean").OnEvent("Click", CopyClean)
Main.Add("Button", "x300 y236 w86 h30", "👁 Ver").OnEvent("Click", OpenClean)
Main.Add("Button", "x392 y236 w86 h30", "📂 Exports").OnEvent("Click", (*) => OpenPath(RF["EXPORTS"]))

Main.Add("Button", "x24 y274 w116 h30", "🧠 Maestro").OnEvent("Click", OpenFull)
Main.Add("Button", "x148 y274 w116 h30", "🚀 Prep V44").OnEvent("Click", (*) => RunCapture("v44-preflight"))
Main.Add("Button", "x272 y274 w116 h30", "🔄 Reiniciar").OnEvent("Click", RestartQuick)
Main.Add("Button", "x396 y274 w82 h30", "✖ Cerrar").OnEvent("Click", (*) => ExitApp())

Main.SetFont("s8 c888888", "Segoe UI")
Main.Add("Text", "x18 y320 w510 h22", "Hotkeys: Ctrl+Alt+M mini | Ctrl+Alt+P maestro | Ctrl+Alt+S shell | Ctrl+Alt+C clean")

Main.Show("w540 h352")

^!m:: {
    global Main
    try {
        if WinActive("RUNEFORGE QUICK DOCK") {
            Main.Hide()
        } else {
            Main.Show()
            WinActivate("RUNEFORGE QUICK DOCK")
        }
    }
}

^!p::OpenFull()
^!s::OpenShell()
^!c::CopyClean()
