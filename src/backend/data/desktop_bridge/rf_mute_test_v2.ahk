#Requires AutoHotkey v2.0
SoundSetMute(-1)
FileAppend(A_Now " MUTE_SENT`n", "C:\RUNEFOGE_PRO\runeforge\data\desktop_bridge\rf_mute_test_v2.log")
ExitApp
