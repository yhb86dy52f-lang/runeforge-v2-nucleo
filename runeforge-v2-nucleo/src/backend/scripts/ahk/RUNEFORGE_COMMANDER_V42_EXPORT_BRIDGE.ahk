#Requires AutoHotkey v2.0
#SingleInstance Force

if not A_IsAdmin {
    Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

global RF := Map(
    "ROOT", "C:\RUNEFOGE_PRO\runeforge",
    "BACKEND", "C:\RUNEFOGE_PRO\runeforge\app",
    "ABISMO", "C:\Users\nesth\Documents\EL_ABISMO",
    "ABISMO_MEM", "C:\Users\nesth\Documents\EL_ABISMO\01_MEMORIAS\memoria_operativa_actual.txt",
    "COMMANDER", "C:\RUNEFOGE_PRO\runeforge\data\commander",
    "SNIPPETS", "C:\RUNEFOGE_PRO\runeforge\data\commander\snippets",
    "TRACE", "C:\RUNEFOGE_PRO\runeforge\data\commander\commander-trace.jsonl",
    "OPMEM", "C:\RUNEFOGE_PRO\runeforge\data\commander\commander-ops-memory.txt",
    "DB", "C:\RUNEFOGE_PRO\runeforge\data\commander\commander-db.json",
    "DOCS", "C:\RUNEFOGE_PRO\runeforge\docs",
    "EXPORT_SOURCE", "C:\Users\nesth\Documents\EL_ABISMO\PWSH RESULTADOS CODIGOS",
    "IMPORTER", "C:\RUNEFOGE_PRO\runeforge\scripts\Import-LatestTerminalExport.ps1",
    "LATEST_TXT", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.txt",
    "LATEST_JSON", "C:\RUNEFOGE_PRO\runeforge\data\commander\exports\latest-terminal-export.json"
)

global TargetHwnd := 0
global Main := ""
global TemplateList := ""
global Preview := ""
global SafeMode := ""
global AutoEnter := ""
global GhostMode := ""

SetTimer(TrackActiveWindow, 250)

TrackActiveWindow() {
    global TargetHwnd
    try {
        hwnd := WinGetID("A")
        title := WinGetTitle("ahk_id " hwnd)
        if (!InStr(title, "RUNEFORGE V42")) {
            TargetHwnd := hwnd
        }
    }
}

Q(s) {
    return Chr(34) . s . Chr(34)
}

Toast(msg, ms := 1800) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -ms)
}

CurrentTs() {
    return FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
}

EscapeJson(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '"', '\"')
    s := StrReplace(s, "`r", "\r")
    s := StrReplace(s, "`n", "\n")
    return s
}

Trace(action, label := "", extra := "") {
    global RF
    try {
        line := '{"ts":"' . EscapeJson(CurrentTs()) . '","action":"' . EscapeJson(action) . '","label":"' . EscapeJson(label) . '","extra":"' . EscapeJson(extra) . '"}' . "`n"
        FileAppend(line, RF["TRACE"], "UTF-8")
    }
}

LimitRead(path, maxChars := 80000) {
    if (!FileExist(path)) {
        return "PENDIENTE: No existe archivo: " . path
    }

    try {
        txt := FileRead(path, "UTF-8")
        if (StrLen(txt) > maxChars) {
            txt := SubStr(txt, 1, maxChars) . "`r`n`r`n...[TRUNCADO_POR_COMMANDER]..."
        }
        return txt
    } catch as err {
        return "ERROR_LEYENDO: " . path . "`r`n" . err.Message
    }
}

SetClip(text, label := "payload") {
    A_Clipboard := text
    ClipWait(1)
    Trace("CLIPBOARD_SET", label, "len=" . StrLen(text))
}

SendTarget(keys) {
    global TargetHwnd

    if (TargetHwnd) {
        try {
            WinActivate("ahk_id " TargetHwnd)
            Sleep(120)
        }
    }

    Send(keys)
    Trace("SEND_KEYS", keys)
}

PasteTextToTarget(text, label := "payload", sendEnter := false) {
    global TargetHwnd

    SetClip(text, label)

    if (TargetHwnd) {
        try {
            WinActivate("ahk_id " TargetHwnd)
            Sleep(140)
        }
    }

    Send("^v")
    Sleep(80)

    if (sendEnter) {
        Send("{Enter}")
    }

    Trace("INJECT_TO_TARGET", label, "enter=" . sendEnter)
}

OpenPath(path) {
    if (FileExist(path)) {
        Run(path)
        Trace("OPEN_PATH", path)
    } else {
        Toast("PENDIENTE: no existe ruta")
        Trace("OPEN_PATH_MISSING", path)
    }
}

OpenTerminalProfile(profileName) {
    try {
        Run("wt.exe -p " . Q(profileName))
        Trace("OPEN_TERMINAL_PROFILE", profileName)
    } catch {
        Run("pwsh.exe")
        Trace("OPEN_TERMINAL_FALLBACK", profileName)
    }
}

RunPwshFile(path, args := "", label := "pwsh_file") {
    if (!FileExist(path)) {
        Toast("No existe script")
        Trace("RUN_PWSH_FILE_MISSING", path)
        return
    }

    cmd := "pwsh.exe -NoExit -ExecutionPolicy Bypass -File " . Q(path)
    if (args != "") {
        cmd .= " " . args
    }

    Run(cmd)
    Trace("RUN_PWSH_FILE", label, path . " " . args)
}

RunPwshCommand(cmd, label := "pwsh") {
    Run("pwsh.exe -NoExit -ExecutionPolicy Bypass -Command " . Q(cmd))
    Trace("RUN_PWSH_COMMAND", label)
}

GetSnippet(label) {
    global RF

    if (InStr(label, "Importar Último Export")) {
        return LimitRead(RF["SNIPPETS"] . "\code_import_latest_terminal_export.ps1")
    }

    if (InStr(label, "Importar+Abrir Export")) {
        return LimitRead(RF["SNIPPETS"] . "\code_import_open_latest_terminal_export.ps1")
    }

    if (InStr(label, "Analizar Export")) {
        return LimitRead(RF["SNIPPETS"] . "\prompt_analyze_latest_terminal_export.txt")
    }

    if (InStr(label, "Resultado Latest")) {
        return LimitRead(RF["LATEST_TXT"], 120000)
    }

    if (InStr(label, "Estado")) {
        return LimitRead(RF["SNIPPETS"] . "\code_status_check.ps1")
    }

    if (InStr(label, "Memoria Estado")) {
        return BuildMemoryPack()
    }

    if (InStr(label, "Memoria Operador")) {
        return LimitRead(RF["SNIPPETS"] . "\prompt_memory_operator.txt")
    }

    return "PENDIENTE: plantilla no encontrada."
}

BuildMemoryPack() {
    global RF

    current := RF["DOCS"] . "\RUNEFORGE_CURRENT_STATE_MEMORY.md"
    hardened := RF["DOCS"] . "\RUNEFORGE_HARDENED_STATE_MEMORY.md"
    latest := RF["LATEST_TXT"]

    txt := "### RUNEFORGE_MEMORY_PACK_V42_EXPORT_BRIDGE`r`n"
    txt .= "fecha=" . CurrentTs() . "`r`n"
    txt .= "root=" . RF["ROOT"] . "`r`n"
    txt .= "backend=" . RF["BACKEND"] . "`r`n"
    txt .= "export_source=" . RF["EXPORT_SOURCE"] . "`r`n"
    txt .= "latest_export=" . RF["LATEST_TXT"] . "`r`n"
    txt .= "modo=LOCAL_FIRST_SAFE_EXPORT_BRIDGE`r`n`r`n"

    txt .= "## CURRENT_STATE`r`n"
    txt .= LimitRead(current, 25000) . "`r`n`r`n"

    txt .= "## HARDENED_STATE`r`n"
    txt .= LimitRead(hardened, 25000) . "`r`n`r`n"

    txt .= "## LATEST_TERMINAL_EXPORT`r`n"
    txt .= LimitRead(latest, 50000) . "`r`n`r`n"

    txt .= "## ABISMO_MEMORY_SNIPPET`r`n"
    txt .= LimitRead(RF["ABISMO_MEM"], 30000)

    return txt
}

UpdatePreview(*) {
    global TemplateList, Preview
    label := TemplateList.Text
    payload := GetSnippet(label)
    Preview.Value := payload
    Trace("PREVIEW_TEMPLATE", label, "len=" . StrLen(payload))
}

InjectSelected(mode := "copy") {
    global TemplateList, Preview, SafeMode, AutoEnter

    label := TemplateList.Text
    payload := GetSnippet(label)
    Preview.Value := payload

    if (payload = "") {
        Toast("Payload vacío")
        return
    }

    if (mode = "copy") {
        SetClip(payload, label)
        Toast("Copiado: " . label)
        return
    }

    if (SafeMode.Value) {
        SetClip(payload, label)
        Toast("Modo seguro: copiado, no pegado")
        return
    }

    sendEnter := (mode = "paste_enter") || AutoEnter.Value
    PasteTextToTarget(payload, label, sendEnter)
    Toast(sendEnter ? "Inyectado + Enter" : "Inyectado")
}

ImportLatest(*) {
    global RF
    RunPwshFile(RF["IMPORTER"], "", "import_latest_terminal_export")
    Toast("Importando último export")
}

ImportLatestOpen(*) {
    global RF
    RunPwshFile(RF["IMPORTER"], "-OpenAfter", "import_latest_terminal_export_open")
    Toast("Importando + abriendo")
}

CopyLatestResult(*) {
    global RF, Preview
    txt := LimitRead(RF["LATEST_TXT"], 160000)
    Preview.Value := txt
    SetClip(txt, "LATEST_TERMINAL_EXPORT")
    Toast("Resultado latest copiado")
}

PasteLatestResult(*) {
    global RF, SafeMode, Preview
    txt := LimitRead(RF["LATEST_TXT"], 160000)
    Preview.Value := txt

    if (SafeMode.Value) {
        SetClip(txt, "LATEST_TERMINAL_EXPORT")
        Toast("Modo seguro: copiado")
        return
    }

    PasteTextToTarget(txt, "LATEST_TERMINAL_EXPORT", false)
    Toast("Resultado pegado")
}

AnalyzeLatestExport(*) {
    global RF, Preview, SafeMode
    prompt := LimitRead(RF["SNIPPETS"] . "\prompt_analyze_latest_terminal_export.txt", 20000)
    latest := LimitRead(RF["LATEST_TXT"], 100000)

    payload := prompt . "`r`n`r`n--- ÚLTIMO RESULTADO IMPORTADO ---`r`n" . latest
    Preview.Value := payload

    if (SafeMode.Value) {
        SetClip(payload, "ANALYZE_LATEST_EXPORT")
        Toast("Análisis copiado")
        return
    }

    PasteTextToTarget(payload, "ANALYZE_LATEST_EXPORT", false)
    Toast("Prompt de análisis pegado")
}

SaveClipboardToMemory(*) {
    global RF

    if (A_Clipboard = "") {
        Toast("Portapapeles vacío")
        return
    }

    result := MsgBox(
        "Esto guardará el portapapeles en commander-ops-memory.txt.`n`nNo guardes tokens, claves o contraseñas.`n`n¿Continuar?",
        "Runeforge Commander",
        "YesNo Icon!"
    )

    if (result != "Yes") {
        Toast("Cancelado")
        return
    }

    data := "`r`n`r`n--- COMMANDER_UPDATE " . CurrentTs() . " ---`r`n" . A_Clipboard
    FileAppend(data, RF["OPMEM"], "UTF-8")
    Trace("SAVE_CLIPBOARD_TO_MEMORY", "OPMEM", "len=" . StrLen(A_Clipboard))
    Toast("Memoria operativa actualizada")
}

InsertCustomText(*) {
    global Preview, SafeMode

    payload := Preview.Value

    if (payload = "") {
        Toast("Preview vacío")
        return
    }

    if (SafeMode.Value) {
        SetClip(payload, "CUSTOM_PREVIEW")
        Toast("Modo seguro: copiado")
        return
    }

    PasteTextToTarget(payload, "CUSTOM_PREVIEW", false)
    Toast("Preview inyectado")
}

ToggleGhost(*) {
    global Main, GhostMode
    try {
        if (GhostMode.Value) {
            
        } else {
            WinSetTransparent(255, "ahk_id " Main.Hwnd)
        }
    } catch {
        Toast("No se pudo cambiar Ghost")
    }
}

; ---------------------------------------------------------------------
; GUI
; ---------------------------------------------------------------------

Main := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "RUNEFORGE V42 EXPORT BRIDGE")
Main.BackColor := "050505"
Main.MarginX := 14
Main.MarginY := 12
WinSetTransparent(218, "ahk_id " Main.Hwnd)

Main.SetFont("s12 c39FF14 bold", "Consolas")
Main.Add("Text", "x0 y0 w880 h38 Center 0x200 Background000000", "ᚱ RUNEFORGE COMMANDER V42 // EXPORT BRIDGE")

Main.SetFont("s8 c666666 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y48 w852 h84", "FAST INPUT")
Main.SetFont("s9 cF4EAFF bold", "Segoe UI")
Main.Add("Button", "x30 y72 w68 h32", "Snap").OnEvent("Click", (*) => Send("#+s"))
Main.Add("Button", "x104 y72 w68 h32", "Enter").OnEvent("Click", (*) => SendTarget("{Enter}"))
Main.Add("Button", "x178 y72 w76 h32", "Copiar").OnEvent("Click", (*) => SendTarget("^c"))
Main.Add("Button", "x260 y72 w76 h32", "Pegar").OnEvent("Click", (*) => SendTarget("^v"))
Main.Add("Button", "x342 y72 w112 h32", "Pegar+Enter").OnEvent("Click", (*) => (SendTarget("^v"), Sleep(80), SendTarget("{Enter}")))
Main.Add("Button", "x462 y72 w68 h32", "Esc").OnEvent("Click", (*) => SendTarget("{Esc}"))
Main.Add("Button", "x538 y72 w112 h32", "Guardar Clip").OnEvent("Click", SaveClipboardToMemory)

SafeMode := Main.Add("Checkbox", "x30 y108 w160 h20 Checked", "Modo seguro")
AutoEnter := Main.Add("Checkbox", "x200 y108 w150 h20", "Auto Enter")
GhostMode := Main.Add("Checkbox", "x360 y108 w150 h20 Checked", "Ghost UI")
GhostMode.OnEvent("Click", ToggleGhost)

Main.SetFont("s8 c666666 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y142 w426 h190", "TERMINAL EXPORT BRIDGE")
Main.SetFont("s9 cF4EAFF bold", "Segoe UI")
Main.Add("Button", "x30 y168 w126 h34", "Abrir Export").OnEvent("Click", (*) => OpenPath(RF["EXPORT_SOURCE"]))
Main.Add("Button", "x164 y168 w126 h34", "Importar Último").OnEvent("Click", ImportLatest)
Main.Add("Button", "x298 y168 w126 h34", "Importar+Abrir").OnEvent("Click", ImportLatestOpen)

Main.Add("Button", "x30 y212 w126 h34", "Copiar Resultado").OnEvent("Click", CopyLatestResult)
Main.Add("Button", "x164 y212 w126 h34", "Pegar Resultado").OnEvent("Click", PasteLatestResult)
Main.Add("Button", "x298 y212 w126 h34", "Analizar Export").OnEvent("Click", AnalyzeLatestExport)

Main.Add("Button", "x30 y256 w126 h34", "Ver Latest").OnEvent("Click", (*) => OpenPath(RF["LATEST_TXT"]))
Main.Add("Button", "x164 y256 w126 h34", "Ver Meta").OnEvent("Click", (*) => OpenPath(RF["LATEST_JSON"]))
Main.Add("Button", "x298 y256 w126 h34", "Trace").OnEvent("Click", (*) => OpenPath(RF["TRACE"]))

Main.SetFont("s8 c666666 bold", "Segoe UI")
Main.Add("GroupBox", "x454 y142 w412 h190", "INYECCIÓN / OPS")
Main.SetFont("s9 cF4EAFF", "Segoe UI")

TemplateList := Main.Add("DropDownList", "x470 y168 w376", [
    "IMPORT: Importar Último Export",
    "IMPORT: Importar+Abrir Export",
    "PROMPT: Analizar Export",
    "RESULTADO: Resultado Latest",
    "CODE: Estado Runeforge",
    "MEMORIA: Memoria Estado",
    "PROMPT: Memoria Operador"
])
TemplateList.Choose(1)
TemplateList.OnEvent("Change", UpdatePreview)

Main.Add("Button", "x470 y208 w116 h34", "Copiar").OnEvent("Click", (*) => InjectSelected("copy"))
Main.Add("Button", "x598 y208 w116 h34", "Inyectar").OnEvent("Click", (*) => InjectSelected("paste"))
Main.Add("Button", "x726 y208 w120 h34", "Inyectar+Enter").OnEvent("Click", (*) => InjectSelected("paste_enter"))

Main.Add("Button", "x470 y252 w116 h34", "WT Root").OnEvent("Click", (*) => OpenTerminalProfile("Runeforge Admin"))
Main.Add("Button", "x598 y252 w116 h34", "WT Backend").OnEvent("Click", (*) => OpenTerminalProfile("Runeforge Backend"))
Main.Add("Button", "x726 y252 w120 h34", "PM2").OnEvent("Click", (*) => RunPwshCommand("Set-Location '" . RF["BACKEND"] . "'; pm2 status", "pm2_status"))

Main.Add("Button", "x470 y294 w116 h30", "ROOT").OnEvent("Click", (*) => OpenPath(RF["ROOT"]))
Main.Add("Button", "x598 y294 w116 h30", "Backend").OnEvent("Click", (*) => OpenPath(RF["BACKEND"]))
Main.Add("Button", "x726 y294 w120 h30", "DB").OnEvent("Click", (*) => OpenPath(RF["COMMANDER"]))

Main.SetFont("s8 c666666 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y344 w852 h282", "PREVIEW / PAYLOAD")
Main.SetFont("s9 cF4EAFF", "Consolas")
Preview := Main.Add("Edit", "x30 y370 w820 h204 Multi WantTab -Wrap")

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("Text", "x30 y586 w650 h24", "Hotkeys: Ctrl+Alt+P mostrar/ocultar | Ctrl+Alt+I copiar plantilla | Ctrl+Alt+R reload | Ctrl+Alt+E importar export")
Main.SetFont("s9 cFF4D6D bold", "Segoe UI")
Main.Add("Button", "x730 y582 w120 h30", "Cerrar").OnEvent("Click", (*) => ExitApp())

Main.Show("w880 h644")
Sleep(150)
try {
    if (GhostMode.Value) {
        WinSetTransparent(218, "ahk_id " Main.Hwnd)
    }
}
UpdatePreview()

OnMessage(0x0201, (wParam, lParam, msg, hwnd) => PostMessage(0xA1, 2, 0,, "ahk_id " hwnd))

^!p:: {
    global Main
    try {
        if WinActive("RUNEFORGE V42") {
            Main.Hide()
        } else {
            Main.Show()
            WinActivate("RUNEFORGE V42")
        }
    }
}

^!i::InjectSelected("copy")
^!r::Reload()
^!e::ImportLatest()

