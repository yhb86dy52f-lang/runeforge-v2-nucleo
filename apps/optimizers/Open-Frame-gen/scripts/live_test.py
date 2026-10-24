import sys
import os
import time
import cv2
import torch
import numpy as np
import dxcam
import keyboard
import ctypes

# --- 1. SETUP PATHS ---
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "src"))

try:
    from RIFE_HDv3 import Model
    print("✅ Successfully imported RIFE from src/")
except ImportError as e:
    print(f"❌ Error: Could not import RIFE. {e}")
    sys.exit()

# --- CONFIGURATION ---
MODEL_FOLDER = os.path.join(ROOT, "src") + os.sep
SCALE = 0.5              # 0.5 = 540p (Faster)
KILL_KEY = '='           # Press '=' to quit
WINDOW_NAME = "AI Overlay"

class OverlayTest:
    def __init__(self):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        print(f"🚀 Initializing on {self.device}...")

        # 1. Load Model
        try:
            self.model = Model()
            self.model.load_model(MODEL_FOLDER, -1)
            self.model.eval()
            self.model.device()
            print("🧠 RIFE Model Loaded!")
        except Exception as e:
            print(f"❌ Failed to load model: {e}")
            sys.exit()

        # 2. Setup Camera
        # DXCam returns BGR by default
        self.camera = dxcam.create(output_idx=0, output_color="BGR")
        self.camera.start(target_fps=15, video_mode=True)
        print("📷 DXCam Started.")

        # 3. Setup Overlay Window
        cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)
        cv2.setWindowProperty(WINDOW_NAME, cv2.WND_PROP_TOPMOST, 1)

    def process_frame(self, img0, img1):
        """
        Robust frame processing with explicit color/shape handling.
        """
        h, w, _ = img0.shape

        # OpenCV gives BGR, Model needs RGB
        img0_rgb = cv2.cvtColor(img0, cv2.COLOR_BGR2RGB)
        img1_rgb = cv2.cvtColor(img1, cv2.COLOR_BGR2RGB)

        # We use .copy() to ensure memory is contiguous (Fixes diagonal skew)
        t0 = torch.from_numpy(img0_rgb.copy()).to(self.device).float() / 255.0
        t1 = torch.from_numpy(img1_rgb.copy()).to(self.device).float() / 255.0

        # Current Shape: (H, W, C).  Target Shape: (1, C, H, W)
        t0 = t0.permute(2, 0, 1).unsqueeze(0)
        t1 = t1.permute(2, 0, 1).unsqueeze(0)

        # Padding (Must be divisible by 64)
        ph = ((h - 1) // 64 + 1) * 64
        pw = ((w - 1) // 64 + 1) * 64
        padding = (0, pw - w, 0, ph - h)

        t0 = torch.nn.functional.pad(t0, padding)
        t1 = torch.nn.functional.pad(t1, padding)

        # Inference
        with torch.no_grad():
            prediction = self.model.inference(t0, t1, scale=1.0)

        res = prediction[0, :, :h, :w]

        # (C, H, W) -> (H, W, C)
        res = res.permute(1, 2, 0).cpu().numpy()

        # Clamp to valid range 0-255
        res = np.clip(res * 255.0, 0, 255).astype(np.uint8)

        # Model gave RGB, OpenCV needs BGR to display correctly
        res_bgr = cv2.cvtColor(res, cv2.COLOR_RGB2BGR)

        return res_bgr

    def run(self):
        print(f"\n🟢 OVERLAY STARTED.")
        print(f"   Press '{KILL_KEY}' to Quit.")

        # Wait for camera
        while self.camera.get_latest_frame() is None:
            time.sleep(0.1)

        last_frame = self.camera.get_latest_frame()

        if SCALE != 1.0:
            h, w = last_frame.shape[:2]
            new_dim = (int(w * SCALE), int(h * SCALE))
            last_frame = cv2.resize(last_frame, new_dim)
        else:
            new_dim = None

        frame_count = 0
        t0 = time.time()

        while True:
            if keyboard.is_pressed(KILL_KEY):
                print("\n🛑 Exiting...")
                break

            curr_frame = self.camera.get_latest_frame()
            if curr_frame is None: continue

            if new_dim:
                curr_frame = cv2.resize(curr_frame, new_dim)

            # Inference
            middle_frame = self.process_frame(last_frame, curr_frame)

            # Display
            cv2.imshow(WINDOW_NAME, middle_frame)
            cv2.waitKey(1)

            last_frame = curr_frame

            # FPS Stats
            frame_count += 1
            if time.time() - t0 > 1.0:
                print(f"FPS: {frame_count}", end="\r")
                frame_count = 0
                t0 = time.time()

        self.camera.stop()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    overlay = OverlayTest()
    overlay.run()
