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
    "DOCS", "C:\RUNEFOGE_PRO\runeforge\docs"
)

global TargetHwnd := 0
global Main := ""
global TemplateList := ""
global Preview := ""
global SafeMode := ""
global AutoEnter := ""
global GhostMode := ""
global ReqInput := ""

SetTimer(TrackActiveWindow, 250)

TrackActiveWindow() {
    global TargetHwnd
    try {
        hwnd := WinGetID("A")
        title := WinGetTitle("ahk_id " hwnd)
        if (!InStr(title, "RUNEFORGE V41")) {
            TargetHwnd := hwnd
        }
    }
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

LimitRead(path, maxChars := 50000) {
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
        Run('wt.exe -p "' . profileName . '"')
        Trace("OPEN_TERMINAL_PROFILE", profileName)
    } catch {
        Run("pwsh.exe")
        Trace("OPEN_TERMINAL_FALLBACK", profileName)
    }
}

RunPwshNoExit(cmd, label := "pwsh") {
    try {
        Run('pwsh.exe -NoExit -ExecutionPolicy Bypass -Command "' . cmd . '"')
        Trace("RUN_PWSH_NOEXIT", label)
    } catch as err {
        Toast("Error abriendo PowerShell")
        Trace("RUN_PWSH_ERROR", label, err.Message)
    }
}

GetSnippet(label) {
    global RF

    if (InStr(label, "Estado")) {
        return LimitRead(RF["SNIPPETS"] . "\code_status_check.ps1")
    }

    if (InStr(label, "Backend")) {
        return LimitRead(RF["SNIPPETS"] . "\code_backend_check.ps1")
    }

    if (InStr(label, "Secretos")) {
        return LimitRead(RF["SNIPPETS"] . "\code_secret_triage.ps1")
    }

    if (InStr(label, "Node/PM2")) {
        return LimitRead(RF["SNIPPETS"] . "\code_node_pm2_ports.ps1")
    }

    if (InStr(label, "Extracción")) {
        return LimitRead(RF["SNIPPETS"] . "\request_extraction_v41.txt")
    }

    if (InStr(label, "Programador")) {
        return LimitRead(RF["SNIPPETS"] . "\prompt_code_injection_safe_v41.txt")
    }

    if (InStr(label, "Auditor")) {
        return LimitRead(RF["SNIPPETS"] . "\prompt_security_audit.txt")
    }

    if (InStr(label, "Matriz")) {
        return LimitRead(RF["SNIPPETS"] . "\prompt_canonical_matrix_v41.txt")
    }

    if (InStr(label, "Memoria Estado")) {
        return BuildMemoryPack()
    }

    return "PENDIENTE: plantilla no encontrada."
}

BuildMemoryPack() {
    global RF

    current := RF["DOCS"] . "\RUNEFORGE_CURRENT_STATE_MEMORY.md"
    hardened := RF["DOCS"] . "\RUNEFORGE_HARDENED_STATE_MEMORY.md"
    prompt := RF["DOCS"] . "\PROMPT_ESTADO_ENDURECIDO_RUNEFORGE.txt"

    txt := "### RUNEFORGE_MEMORY_PACK_V41_GHOST_FUSION`r`n"
    txt .= "fecha=" . CurrentTs() . "`r`n"
    txt .= "root=" . RF["ROOT"] . "`r`n"
    txt .= "backend=" . RF["BACKEND"] . "`r`n"
    txt .= "modo=LOCAL_FIRST_SAFE_GHOST_INJECTION`r`n`r`n"

    txt .= "## CURRENT_STATE`r`n"
    txt .= LimitRead(current, 25000) . "`r`n`r`n"

    txt .= "## HARDENED_STATE`r`n"
    txt .= LimitRead(hardened, 25000) . "`r`n`r`n"

    txt .= "## HARDENED_PROMPT`r`n"
    txt .= LimitRead(prompt, 20000) . "`r`n`r`n"

    txt .= "## ABISMO_OPERATIVE_MEMORY_SNIPPET`r`n"
    txt .= LimitRead(RF["ABISMO_MEM"], 30000) . "`r`n"

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

InjectRequest(*) {
    global ReqInput, SafeMode

    req := Trim(ReqInput.Value)

    if (req = "" || req = "REQ_ID_") {
        Toast("Falta REQ_ID")
        return
    }

    payload := "[RUNEFORGE_REQUEST]`r`n"
    payload .= "id=" . req . "`r`n"
    payload .= "ts=" . CurrentTs() . "`r`n"
    payload .= "flow=INPUT→ROUTER→SKILL→ACTION→TRACE→RESPONSE`r`n"
    payload .= "mode=SAFE_REQUEST_INJECTION`r`n"
    payload .= "action=PENDIENTE_EN_BACKEND`r`n"

    if (SafeMode.Value) {
        SetClip(payload, "REQUEST_" . req)
        Toast("REQ copiado en modo seguro")
        return
    }

    PasteTextToTarget(payload, "REQUEST_" . req, false)
    Toast("REQ inyectado")
}

ToggleGhost(*) {
    global Main, GhostMode

    try {
        if (GhostMode.Value) {
            Main.Opt("+LastFound")
            WinSetTransparent(215)
            Trace("GHOST_MODE", "ON")
        } else {
            Main.Opt("+LastFound")
            WinSetTransparent(255)
            Trace("GHOST_MODE", "OFF")
        }
    } catch {
        Toast("No se pudo cambiar transparencia")
    }
}

; ---------------------------------------------------------------------
; GUI
; ---------------------------------------------------------------------

Main := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000000", "RUNEFORGE V41 GHOST FUSION")
Main.BackColor := "050505"
Main.MarginX := 14
Main.MarginY := 12
Main.Opt("+LastFound")
WinSetTransparent(215)

Main.SetFont("s12 c39FF14 bold", "Consolas")
Main.Add("Text", "x0 y0 w820 h38 Center 0x200 Background000000", "ᚱ RUNEFORGE COMMANDER V41 // GHOST FUSION")

Main.SetFont("s8 c666666 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y48 w790 h88", "MULTIMEDIA & FAST INPUT")
Main.SetFont("s9 cF4EAFF bold", "Segoe UI")
Main.Add("Button", "x30 y72 w70 h34", "⏯️").OnEvent("Click", (*) => Send("{Media_Play_Pause}"))
Main.Add("Button", "x106 y72 w70 h34", "🔉").OnEvent("Click", (*) => Send("{Volume_Down 2}"))
Main.Add("Button", "x182 y72 w70 h34", "🔊").OnEvent("Click", (*) => Send("{Volume_Up 2}"))
Main.Add("Button", "x258 y72 w82 h34", "📸 Snap").OnEvent("Click", (*) => Send("#+s"))
Main.Add("Button", "x346 y72 w70 h34", "Enter").OnEvent("Click", (*) => SendTarget("{Enter}"))
Main.Add("Button", "x422 y72 w82 h34", "Copiar").OnEvent("Click", (*) => SendTarget("^c"))
Main.Add("Button", "x510 y72 w82 h34", "Pegar").OnEvent("Click", (*) => SendTarget("^v"))
Main.Add("Button", "x598 y72 w112 h34", "Pegar+Enter").OnEvent("Click", (*) => (SendTarget("^v"), Sleep(80), SendTarget("{Enter}")))
Main.Add("Button", "x716 y72 w70 h34", "Esc").OnEvent("Click", (*) => SendTarget("{Esc}"))

SafeMode := Main.Add("Checkbox", "x30 y112 w220 h20 Checked", "Modo seguro")
AutoEnter := Main.Add("Checkbox", "x260 y112 w190 h20", "Auto Enter")
GhostMode := Main.Add("Checkbox", "x460 y112 w180 h20 Checked", "Ghost UI")
GhostMode.OnEvent("Click", ToggleGhost)

Main.SetFont("s8 c666666 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y146 w390 h212", "INYECCIONES")
Main.SetFont("s9 cF4EAFF", "Segoe UI")

TemplateList := Main.Add("DropDownList", "x30 y174 w354", [
    "CODE: Estado Runeforge",
    "CODE: Backend Check",
    "CODE: Secretos Redacted",
    "CODE: Node/PM2 Ports",
    "PROMPT: Programador Senior",
    "PROMPT: Auditor Seguridad",
    "PROMPT: Matriz Canónica",
    "MEMORIA: Memoria Estado",
    "REQUEST: Solicitud Extracción"
])
TemplateList.Choose(1)
TemplateList.OnEvent("Change", UpdatePreview)

Main.Add("Button", "x30 y214 w105 h34", "Copiar").OnEvent("Click", (*) => InjectSelected("copy"))
Main.Add("Button", "x144 y214 w105 h34", "Inyectar").OnEvent("Click", (*) => InjectSelected("paste"))
Main.Add("Button", "x258 y214 w126 h34", "Inyectar+Enter").OnEvent("Click", (*) => InjectSelected("paste_enter"))

Main.Add("Button", "x30 y258 w166 h34", "Preview").OnEvent("Click", UpdatePreview)
Main.Add("Button", "x208 y258 w176 h34", "Inyectar Preview").OnEvent("Click", InsertCustomText)

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("Text", "x30 y306 w90 h20", "REQ ID")
ReqInput := Main.Add("Edit", "x90 y300 w182 h30 Background111111 c39FF14", "REQ_ID_")
Main.Add("Button", "x282 y300 w102 h30", "REQ SEND").OnEvent("Click", InjectRequest)

Main.SetFont("s8 c666666 bold", "Segoe UI")
Main.Add("GroupBox", "x420 y146 w384 h212", "NAVEGACIÓN / OPS")
Main.SetFont("s9 cF4EAFF bold", "Segoe UI")
Main.Add("Button", "x436 y174 w110 h34", "ROOT").OnEvent("Click", (*) => OpenPath(RF["ROOT"]))
Main.Add("Button", "x554 y174 w110 h34", "Backend").OnEvent("Click", (*) => OpenPath(RF["BACKEND"]))
Main.Add("Button", "x672 y174 w110 h34", "DB").OnEvent("Click", (*) => OpenPath(RF["COMMANDER"]))

Main.Add("Button", "x436 y218 w110 h34", "WT Root").OnEvent("Click", (*) => OpenTerminalProfile("Runeforge Admin"))
Main.Add("Button", "x554 y218 w110 h34", "WT Backend").OnEvent("Click", (*) => OpenTerminalProfile("Runeforge Backend"))
Main.Add("Button", "x672 y218 w110 h34", "WT Audits").OnEvent("Click", (*) => OpenTerminalProfile("Runeforge Audits"))

Main.Add("Button", "x436 y262 w110 h34", "PM2").OnEvent("Click", (*) => RunPwshNoExit("Set-Location '" . RF["BACKEND"] . "'; pm2 status", "pm2_status"))
Main.Add("Button", "x554 y262 w110 h34", "Tailscale").OnEvent("Click", (*) => RunPwshNoExit("tailscale status", "tailscale_status"))
Main.Add("Button", "x672 y262 w110 h34", "Puertos").OnEvent("Click", (*) => RunPwshNoExit("Get-NetTCPConnection -State Listen | Sort-Object LocalPort | Select-Object LocalAddress,LocalPort,OwningProcess | Format-Table -AutoSize", "ports"))

Main.Add("Button", "x436 y306 w170 h34", "Guardar Clip").OnEvent("Click", SaveClipboardToMemory)
Main.Add("Button", "x614 y306 w168 h34", "Reload").OnEvent("Click", (*) => Reload())

Main.SetFont("s8 c666666 bold", "Segoe UI")
Main.Add("GroupBox", "x14 y370 w790 h252", "PREVIEW / EDITOR DE PAYLOAD")
Main.SetFont("s9 cF4EAFF", "Consolas")
Preview := Main.Add("Edit", "x30 y396 w756 h180 Multi WantTab -Wrap")

Main.SetFont("s8 cB79AC7 bold", "Segoe UI")
Main.Add("Text", "x30 y584 w610 h24", "Hotkeys: Ctrl+Alt+P mostrar/ocultar | Ctrl+Alt+I copiar plantilla | Ctrl+Alt+Enter enviar Enter | Ctrl+Alt+R reload")
Main.SetFont("s9 cFF4D6D bold", "Segoe UI")
Main.Add("Button", "x666 y580 w120 h30", "Cerrar").OnEvent("Click", (*) => ExitApp())

Main.Show("w820 h640")
UpdatePreview()

OnMessage(0x0201, (wParam, lParam, msg, hwnd) => PostMessage(0xA1, 2, 0,, "ahk_id " hwnd))

^!p:: {
    global Main
    try {
        if WinActive("RUNEFORGE V41") {
            Main.Hide()
        } else {
            Main.Show()
            WinActivate("RUNEFORGE V41")
        }
    }
}

^!i::InjectSelected("copy")
^!Enter::SendTarget("{Enter}")
^!r::Reload()
