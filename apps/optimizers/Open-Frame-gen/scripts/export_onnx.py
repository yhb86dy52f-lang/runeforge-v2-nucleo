import torch
import torch.onnx
import sys
import os
import warnings
import traceback

# Suppress verbose ONNX warnings
warnings.filterwarnings('ignore')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "src"))
from nano import NanoModel

def export_to_onnx():
    print("[*] Loading Nano model (FP16)...")
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # Export in FP16 for the engine
    model = NanoModel().to(device).half().eval()

    model_path = os.path.join(ROOT, "checkpoints", "nano_v17_best.pth")
    if os.path.exists(model_path):
        try:
            model.load_state_dict(torch.load(model_path, map_location=device, weights_only=True), strict=False)
            print(f"    Loaded weights from {model_path}")
        except Exception as e:
            print(f"    [WARNING] Weight load failed: {e}")
    else:
        print("    WARNING: No weights found.")

    # Use 50% resolution as the default trace shape
    # TensorRT will optimize for the profile range (40-60%)
    H, W = 544, 960  # 50% of 1080p, rounded to 32
    dummy_input = torch.randn(1, 6, H, W, dtype=torch.float16, device=device)

    onnx_path = os.path.join(ROOT, "checkpoints", "nano_v16.onnx")
    print(f"[*] Exporting to {onnx_path} (FP16, dynamic shapes)...")

    try:
        with torch.no_grad():
            torch.onnx.export(
                model,
                dummy_input,
                onnx_path,
                export_params=True,
                opset_version=16,
                do_constant_folding=True,
                input_names=['input'],
                output_names=['output'],
                # Enable dynamic axes for TensorRT to use optimization profiles
                dynamic_axes={
                    'input': {2: 'height', 3: 'width'},
                    'output': {2: 'height', 3: 'width'}
                }
            )
        print(f"[OK] Successfully exported: {onnx_path}")
        print(f"     Default shape: [1, 6, {H}, {W}] (50%)")
        print(f"     Dynamic H/W enabled for quality scaling")

        # Clean up old engine files
        for eng in [onnx_path + ".engine", os.path.join(ROOT, "checkpoints", "nano_v16.engine")]:
            if os.path.exists(eng):
                os.remove(eng)
                print(f"[*] Deleted old engine: {eng}")

        print("\n[NEXT] Rebuild engine_cpp project and run it.")
        print("       TensorRT will auto-build a new optimized engine.")
        print("\n[QUALITY LEVELS]")
        print("       40% = 736x416 (Fast, ~100+ FPS)")
        print("       50% = 960x544 (Balanced, ~70 FPS)")
        print("       60% = 1152x640 (Quality, ~50 FPS)")

    except Exception as e:
        print(f"[ERROR] ONNX Export failed. See error_export.log")
        with open("error_export.log", "w") as f:
            f.write(str(e) + "\n")
            f.write(traceback.format_exc())

if __name__ == "__main__":
    export_to_onnx()
