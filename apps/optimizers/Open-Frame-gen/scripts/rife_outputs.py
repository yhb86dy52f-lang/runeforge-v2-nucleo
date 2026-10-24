import os
import cv2
import torch
import sys
import numpy as np

# --- CONFIG ---
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_PATH = os.path.join(ROOT, "dataset", "raw", "images")
OUT_PATH = os.path.join(ROOT, "dataset", "teacher_targets")
W, H = 640, 384  # Training Resolution

# --- SETUP ---
sys.path.insert(0, os.path.join(ROOT, "src"))
try:
    from RIFE_HDv3 import Model as TeacherModel
    print("✅ RIFE Loaded.")
except ImportError:
    print("❌ Error: src/RIFE_HDv3.py not found.")
    sys.exit()

def bake():
    if not os.path.exists(DATA_PATH):
        print(f"❌ Error: {DATA_PATH} does not exist.")
        return

    os.makedirs(OUT_PATH, exist_ok=True)
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    print(f"👨‍🏫 Loading Teacher on {device}...")
    teacher = TeacherModel()
    teacher.load_model(os.path.join(ROOT, "src") + os.sep, -1)
    teacher.eval()
    teacher.device()

    frames = sorted([f for f in os.listdir(DATA_PATH) if f.endswith(".jpg")])
    print(f"🍪 Baking targets for {len(frames)-2} triplets...")

    count = 0
    for i in range(len(frames) - 2):
        # 1. Load Input Frames
        p0 = os.path.join(DATA_PATH, frames[i])
        p2 = os.path.join(DATA_PATH, frames[i+2])

        # 2. Resize
        img0 = cv2.resize(cv2.imread(p0), (W, H))
        img1 = cv2.resize(cv2.imread(p2), (W, H))

        # 3. To Tensor
        t0 = torch.from_numpy(img0[:, :, ::-1].copy()).permute(2, 0, 1).float().to(device) / 255.0
        t1 = torch.from_numpy(img1[:, :, ::-1].copy()).permute(2, 0, 1).float().to(device) / 255.0
        t0, t1 = t0.unsqueeze(0), t1.unsqueeze(0)

        # 4. Teacher Inference
        with torch.no_grad():
            pred = teacher.inference(t0, t1, scale=1.0)

        # 5. Convert back to Image
        res = pred[0].permute(1, 2, 0).cpu().numpy() * 255.0
        res = np.clip(res, 0, 255).astype('uint8')[:, :, ::-1] # RGB -> BGR

        # 6. Save (Name matches the Middle Frame)
        # If input is 0.jpg and 2.jpg, target is 1.jpg
        target_name = frames[i+1]
        cv2.imwrite(os.path.join(OUT_PATH, target_name), res)

        count += 1
        if count % 50 == 0:
            print(f"   Baked {count} frames...", end="\r")

    print(f"\n✅ Done! {count} targets saved to {OUT_PATH}")

if __name__ == "__main__":
    bake()
