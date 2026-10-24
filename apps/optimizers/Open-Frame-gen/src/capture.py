import dxcam
import numpy as np
import time
import threading
from pynput import keyboard, mouse

class InputCapture:
    def __init__(self, fps=60):
        # 1. Screen Capture
        self.camera = dxcam.create(output_idx=0, output_color="BGR")
        self.camera.start(target_fps=fps, video_mode=True)
        
        # 2. Input Tracking (Thread-Safe)
        self.lock = threading.Lock()
        self.mouse_accum = {"dx": 0, "dy": 0}
        self.key_state = {"w": 0, "a": 0, "s": 0, "d": 0}
        self.last_mouse_pos = None

        # Start Listeners
        self.m_listener = mouse.Listener(on_move=self._on_move)
        self.k_listener = keyboard.Listener(on_press=self._on_press, on_release=self._on_release)
        self.m_listener.start()
        self.k_listener.start()

    def _on_move(self, x, y):
        with self.lock:
            if self.last_mouse_pos is not None:
                self.mouse_accum["dx"] += x - self.last_mouse_pos[0]
                self.mouse_accum["dy"] += y - self.last_mouse_pos[1]
            self.last_mouse_pos = (x, y)

    def _on_press(self, key):
        try:
            k = key.char.lower()
            if k in self.key_state:
                with self.lock: self.key_state[k] = 1
        except AttributeError: pass

    def _on_release(self, key):
        try:
            k = key.char.lower()
            if k in self.key_state:
                with self.lock: self.key_state[k] = 0
        except AttributeError: pass

    def get_snapshot(self):
        """
        Returns: (Frame_Now, Input_Vector)
        Input_Vector: [dx, dy, w, a, s, d]
        """
        # A. Get Frame
        frame = self.camera.get_latest_frame()
        
        # B. Get & Reset Inputs
        with self.lock:
            dx = self.mouse_accum["dx"] / 50.0 # Normalize
            dy = self.mouse_accum["dy"] / 50.0
            w = self.key_state["w"]
            a = self.key_state["a"]
            s = self.key_state["s"]
            d = self.key_state["d"]
            
            # Reset delta (Movement is relative to last frame)
            self.mouse_accum["dx"] = 0
            self.mouse_accum["dy"] = 0

        input_vec = np.array([dx, dy, w, a, s, d], dtype=np.float32)
        
        return frame, input_vec

    def stop(self):
        self.camera.stop()
        self.m_listener.stop()
        self.k_listener.stop()