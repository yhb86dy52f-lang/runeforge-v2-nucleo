#Requires AutoHotkey v2.0
SoundSetMute(0)
SoundSetVolume(35)
FileAppend(A_Now " UNMUTE_SENT`n", "C:\RUNEFOGE_PRO\runeforge\data\desktop_bridge\rf_unmute.log")
ExitApp
