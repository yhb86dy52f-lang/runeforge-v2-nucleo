Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\RUNEFORGE_V2_CORE\ble-bridge"
WshShell.Run "cmd /c venv\Scripts\python.exe server.py", 0, False

