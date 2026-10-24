Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\RUNEFORGE_V2_CORE\whisper-backend"
WshShell.Run """C:\RUNEFORGE_V2_CORE\whisper-backend\venv\Scripts\python.exe"" server.py", 0, False
