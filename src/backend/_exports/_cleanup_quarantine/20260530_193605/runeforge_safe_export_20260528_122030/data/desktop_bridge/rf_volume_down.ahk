#Requires AutoHotkey v2.0
Send "{Volume_Down 5}"
FileAppend(A_Now " VOLUME_DOWN_SENT`n", "C:\RUNEFOGE_PRO\runeforge\data\desktop_bridge\rf_volume_down.log")
ExitApp
