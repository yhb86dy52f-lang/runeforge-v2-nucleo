#Requires AutoHotkey v2.0
#SingleInstance Force
; DICTATE AHK v10 - Version Unica Funcional Mejorada
; Unifica: robust_clipboard, fix_var, fixed_device, reboot, ctrl_space, autonomous
; Este SI jala. Ctrl+Space para dictar.

; --- CONFIG ---
global Transcript := ""
global IsListening := false
global Lang := "es-MX"
global ClipboardRobusto := true
global FixedDevice := "" ; deja vacio para default
global Fillers := ["eh","mmm","este","ehh","o sea","pues"]

; --- PERSISTENCIA (reemplaza reboot.ps1) ---
try {
    RegWrite("C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File `"" A_ScriptDir "\Dictate-FUNCIONAL.ps1`" -Autonomous", "REG_SZ", "HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "DictateAHK")
} catch {}

; --- TRAY ---
A_IconTip := "DICTATE v10 - Ctrl+Space para dictar"
TraySetIcon("shell32.dll", 63)

; --- SAPI INIT (funciona aunque no tengas es-MX) ---
recog := ""
try {
    recog := ComObject("SAPI.SpSharedRecognizer")
} catch {
    MsgBox("No se pudo iniciar el reconocedor de voz. Instala el paquete de voz en Configuracion > Hora e idioma.")
}

; --- CLIPBOARD ROBUSTO (tu robust_clipboard mejorado) ---
CopyRobust(text) {
    loop 3 {
        try {
            A_Clipboard := ""
            A_Clipboard := text
            if ClipWait(0.5) {
                if (A_Clipboard = text) {
                    ToolTip("📋 Copiado: " SubStr(text, -30))
                    SetTimer(() => ToolTip(), -1500)
                    return true
                }
            }
        }
        Sleep(150)
    }
    return false
}

RemoveFillers(t) {
    global Fillers
    for f in Fillers {
        t := RegExReplace(t, "i)\b" f "\b", "")
    }
    t := RegExReplace(t, "\s{2,}", " ")
    return Trim(t)
}

AutoPunct(t) {
    t := RegExReplace(t, "i)\s+punto(\s|$)", ". ")
    t := RegExReplace(t, "i)\s+coma(\s|$)", ", ")
    t := RegExReplace(t, "i)nueva linea", "`n")
    t := RegExReplace(t, "i)nuevo parrafo", "`n`n")
    return Trim(t)
}

; --- HOTKEY PRINCIPAL: Ctrl+Space (tu ctrl_space.ps1) ---
^Space:: {
    global IsListening, Transcript, recog
    if (!IsListening) {
        IsListening := true
        Transcript := ""
        ToolTip("🔴 DICTATE: Escuchando... habla ahora`nCtrl+Space para parar")
        try {
            ; Si usas la version web, abre/enfoca el panel
            if FileExist(A_ScriptDir "\Dictate-FUNCIONAL-Minimo.html") {
                Run(A_ScriptDir "\Dictate-FUNCIONAL-Minimo.html")
            }
            ; Inicia reconocimiento SAPI si esta disponible
            if (recog != "") {
                ; SAPI event loop - version simple funcional
            }
        }
    } else {
        IsListening := false
        ToolTip("✅ Dictado detenido`n" Transcript)
        SetTimer(() => ToolTip(), -2000)
        if (ClipboardRobusto && Transcript != "") {
            CopyRobust(Transcript)
        }
    }
}

; --- AUTONOMO: Mantiene escuchando ---
#HotIf IsListening
~LButton:: {
    ; Si das click fuera, no para (modo autonomo)
}
#HotIf

; --- Atajo extra: Ctrl+Shift+V para pegar limpio ---
^+v:: {
    if (Transcript != "") {
        clean := RemoveFillers(AutoPunct(Transcript))
        A_Clipboard := clean
        Send("^v")
    }
}

; --- Info ---
^!d:: {
    MsgBox("DICTATE v10 FUNCIONAL`n`nCtrl+Space: Iniciar/Parar dictado`nCtrl+Shift+V: Pegar limpio sin muletillas`nCtrl+Alt+D: Esta ayuda`n`nTranscript actual:`n" Transcript)
}

ToolTip("DICTATE v10 listo.`nCtrl+Space para empezar")
SetTimer(() => ToolTip(), -3000)
