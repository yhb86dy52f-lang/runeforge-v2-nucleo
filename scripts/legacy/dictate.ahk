#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

global BASE := "C:\WhisperCLI"
global FLAG_REC := BASE "\recording.flag"
global FLAG_PROC := BASE "\processing.flag"
global FILE_RESULT := BASE "\result.txt"
global DAEMON := BASE "\daemon_v3.py"
global isRecording := false

if!ProcessExist("python.exe")
    try Run('python "' DAEMON '"', BASE, "Hide")

F4::Toggle()
Esc:: {
    global isRecording, FLAG_REC, FLAG_PROC
    if (isRecording) {
        isRecording := false
        try FileDelete(FLAG_REC)
        try FileDelete(FLAG_PROC)
        ToolTip("❌ Cancelado")
        SetTimer(() => ToolTip(), -1000)
    }
}

Toggle() {
    global isRecording, FLAG_REC, FLAG_PROC, FILE_RESULT
    isRecording :=!isRecording
    if (isRecording) {
        A_Clipboard := ""
        try FileDelete(FILE_RESULT)
        FileAppend("recording", FLAG_REC, "UTF-8")
        ToolTip("🎙 Grabando... deja de hablar y corta solo")
    } else {
        try FileDelete(FLAG_REC)
        ToolTip("⏳...")
        timeout := 0
        while FileExist(FLAG_PROC) && timeout < 150 {
            Sleep(50)
            timeout++
        }
        if FileExist(FILE_RESULT) {
            try {
                txt := FileRead(FILE_RESULT, "UTF-8")
                if (txt!= "") {
                    A_Clipboard := txt
                    ClipWait(0.5)
                    Send("^v")
                    ToolTip("✅ " txt)
                    SetTimer(() => ToolTip(), -1500)
                    return
                }
            }
        }
        ToolTip("⚠ Vacio")
        SetTimer(() => ToolTip(), -1200)
    }
}
