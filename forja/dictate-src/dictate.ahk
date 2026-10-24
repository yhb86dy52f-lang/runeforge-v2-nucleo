#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetTitleMatchMode 2

global WHISPER_DIR := "C:\WhisperCLI"
global FLAG_REC := WHISPER_DIR "\recording.flag"
global FLAG_PROC := WHISPER_DIR "\processing.flag"
global FILE_RESULT := WHISPER_DIR "\result.txt"
global DAEMON := WHISPER_DIR "\daemon_v3.py"
global isRecording := false

if !ProcessExist("python.exe") {
    try Run('python "' DAEMON '"', WHISPER_DIR, "Hide")
}

F4::ToggleDictado()
Esc:: {
    global isRecording, FLAG_REC, FLAG_PROC
    if (isRecording) {
        isRecording := false
        try FileDelete(FLAG_REC)
        try FileDelete(FLAG_PROC)
        ToolTip("❌ Cancelado")
        SetTimer(() => ToolTip(), -1500)
    }
}

ToggleDictado() {
    global isRecording, FLAG_REC, FLAG_PROC, FILE_RESULT
    isRecording := !isRecording
    if (isRecording) {
        A_Clipboard := ""
        try FileDelete(FILE_RESULT)
        try FileDelete(FLAG_PROC)
        try FileDelete(FLAG_REC)
        FileAppend("recording", FLAG_REC, "UTF-8")
        ToolTip("🎙 [GRABANDO] Habla claro... F4 para parar")
    } else {
        try FileDelete(FLAG_REC)
        ToolTip("⏳ Procesando IA...")
        timeout := 0
        while FileExist(FLAG_PROC) && timeout < 100 {
            Sleep(100)
            timeout++
        }
        if FileExist(FILE_RESULT) {
            try {
                texto := FileRead(FILE_RESULT, "UTF-8")
                if (texto != "")
                    A_Clipboard := texto
            }
        }
        if (A_Clipboard != "") {
            ClipWait(1)
            ToolTip("✅ Pegando...")
            Sleep(150)
            Send("^v")
            SetTimer(() => ToolTip(), -1200)
            SetTimer(() => A_Clipboard := "", -5000)
        } else {
            ToolTip("⚠ No se detecto voz")
            SetTimer(() => ToolTip(), -2000)
        }
    }
}
