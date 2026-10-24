from pynput import keyboard as pynput_kb
from PyQt5.QtCore import QThread, pyqtSignal
from PyQt5.QtWidgets import QApplication
import sys
# ─────────────────────────────────────────────
#  GLOBAL HOTKEY LISTENER
# ─────────────────────────────────────────────
class GlobalHotkey(QThread):
    # We send a signal to the GUI thread when the key is pressed
    on_toggle = pyqtSignal()

    def run(self):
        # Define your hotkey here (e.g., 'Insert', 'F1', '<ctrl>+<alt>+o')
        with pynput_kb.GlobalHotKeys({'<ctrl>+l': self.emit_signal}) as h:
            h.join()

    def emit_signal(self):
        self.on_toggle.emit()
        return False
