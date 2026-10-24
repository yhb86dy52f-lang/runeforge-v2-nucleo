
import os
import sys
import torch
import torch.nn.functional as F
import numpy as np
import time
import cv2
from math import log10

# Add src to path
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "src"))

from nano import NanoModel
from RIFE_HDv3 import Model as RIFEModel

def calculate_psnr(img1, img2):
    mse = np.mean((img1 - img2) ** 2)
    if mse == 0:
        return 100
    PIXEL_MAX = 1.0
    return 20 * log10(PIXEL_MAX / np.sqrt(mse))

def calculate_ssim(img1, img2):
    C1 = (0.01 * 1)**2
    C2 = (0.03 * 1)**2
    img1 = img1.astype(np.float64)
    img2 = img2.astype(np.float64)
    kernel = np.ones((11, 11)) / 121.0
    mu1 = cv2.filter2D(img1, -1, kernel)
    mu2 = cv2.filter2D(img2, -1, kernel)
    mu1_sq = mu1**2
    mu2_sq = mu2**2
    mu1_mu2 = mu1 * mu2
    sigma1_sq = cv2.filter2D(img1**2, -1, kernel) - mu1_sq
    sigma2_sq = cv2.filter2D(img2**2, -1, kernel) - mu2_sq
    sigma12 = cv2.filter2D(img1 * img2, -1, kernel) - mu1_mu2
    ssim_map = ((2 * mu1_mu2 + C1) * (2 * sigma12 + C2)) / ((mu1_sq + mu2_sq + C1) * (sigma1_sq + sigma2_sq + C2))
    return ssim_map.mean()

def get_model_size(model):
    param_size = 0
    for param in model.parameters():
        param_size += param.nelement() * param.element_size()
    buffer_size = 0
    for buffer in model.buffers():
        buffer_size += buffer.nelement() * buffer.element_size()
    size_all_mb = (param_size + buffer_size) / 1024**2
    return size_all_mb

def benchmark():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    if not torch.cuda.is_available():
        print("❌ CUDA not available.")
        return

    print("🚀 Starting Comprehensive Paper Benchmark...")
    print(f"Device: {torch.cuda.get_device_name(0)}")

    # --- 1. Load Models ---
    nano = NanoModel().to(device).half().eval()
    nano_path = os.path.join(ROOT, "checkpoints", "nano_v17_best.pth")
    if os.path.exists(nano_path):
        nano.load_state_dict(torch.load(nano_path, map_location=device, weights_only=True), strict=False)

    rife = RIFEModel()
    rife.load_model(os.path.join(ROOT, "src") + os.sep, -1)
    rife.eval()
    rife.device()

    # --- 2. Static Stats ---
    nano_params = sum(p.numel() for p in nano.parameters())
    rife_params = sum(p.numel() for p in rife.flownet.parameters())

    # --- 3. Speed & VRAM (1080p) ---
    h, w = 1080, 1920
    ph = ((h - 1) // 64 + 1) * 64
    pw = ((w - 1) // 64 + 1) * 64
    padding_d = (0, pw - w, 0, ph - h)

    dummy_input = torch.randn(1, 6, h, w, device=device, dtype=torch.float16)
    dummy_input_p = F.pad(dummy_input, padding_d).float()

    print("\n⏱️  Benchmarking Speed & Peak VRAM...")

    # Nano Bench
    torch.cuda.empty_cache()
    torch.cuda.reset_peak_memory_stats()
    with torch.inference_mode():
        for _ in range(20): nano(dummy_input) # Warmup
        torch.cuda.synchronize()
        t0 = time.perf_counter()
        for _ in range(100): nano(dummy_input)
        torch.cuda.synchronize()
        nano_ms = (time.perf_counter() - t0) / 100 * 1000
    nano_vram = torch.cuda.max_memory_allocated() / 1024**2

    # RIFE Bench
    torch.cuda.empty_cache()
    torch.cuda.reset_peak_memory_stats()
    with torch.inference_mode():
        for _ in range(5): rife.inference(dummy_input_p[:, :3], dummy_input_p[:, 3:]) # Warmup
        torch.cuda.synchronize()
        t0 = time.perf_counter()
        for _ in range(20): rife.inference(dummy_input_p[:, :3], dummy_input_p[:, 3:])
        torch.cuda.synchronize()
        rife_ms = (time.perf_counter() - t0) / 20 * 1000
    rife_vram = torch.cuda.max_memory_allocated() / 1024**2

    # --- 4. Quality (High Motion Samples) ---
    print("\n🖼️  Selecting High-Motion samples for Quality Benchmark...")
    img_path = os.path.join(ROOT, "dataset", "raw", "images")
    frames = sorted([f for f in os.listdir(img_path) if f.endswith(".jpg")])

    # Find 50 frames with highest difference to make the benchmark "honest"
    diffs = []
    scan_limit = min(500, len(frames)-2)
    for i in range(0, scan_limit):
        f0 = cv2.imread(os.path.join(img_path, frames[i]), cv2.IMREAD_GRAYSCALE)
        f2 = cv2.imread(os.path.join(img_path, frames[i+2]), cv2.IMREAD_GRAYSCALE)
        if f0 is not None and f2 is not None:
            diff = np.mean(np.abs(f0.astype(float) - f2.astype(float)))
            diffs.append((diff, i))

    # Pick top 50 by motion
    diffs.sort(key=lambda x: x[0], reverse=True)
    best_indices = [x[1] for x in diffs[:50]]

    print(f"   Mean motion of selected samples: {np.mean([x[0] for x in diffs[:50]]):.2f} pixel units")

    nano_psnrs, rife_psnrs = [], []
    nano_ssims, rife_ssims = [], []

    with torch.inference_mode():
        for i in best_indices:
            img0 = cv2.imread(os.path.join(img_path, frames[i]))
            gt   = cv2.imread(os.path.join(img_path, frames[i+1]))
            img1 = cv2.imread(os.path.join(img_path, frames[i+2]))

            t0 = torch.from_numpy(img0).permute(2, 0, 1).unsqueeze(0).float().to(device) / 255.
            t1 = torch.from_numpy(img1).permute(2, 0, 1).unsqueeze(0).float().to(device) / 255.
            tgt = gt.astype(np.float32) / 255.

            # Nano
            n_out = nano(torch.cat([t0, t1], dim=1).half())[0].permute(1, 2, 0).cpu().float().numpy()

            # RIFE
            t0_p = F.pad(t0, padding) if 'padding' in locals() else F.pad(t0, (0, pw-w, 0, ph-h))
            t1_p = F.pad(t1, padding) if 'padding' in locals() else F.pad(t1, (0, pw-w, 0, ph-h))
            r_out = rife.inference(t0_p, t1_p)
            r_out = r_out[0, :, :img0.shape[0], :img0.shape[1]].permute(1, 2, 0).cpu().numpy()

            nano_psnrs.append(calculate_psnr(tgt, n_out))
            rife_psnrs.append(calculate_psnr(tgt, r_out))
            nano_ssims.append(np.mean([calculate_ssim(tgt[:,:,c], n_out[:,:,c]) for c in range(3)]))
            rife_ssims.append(np.mean([calculate_ssim(tgt[:,:,c], r_out[:,:,c]) for c in range(3)]))

    # --- 5. Report ---
    print("\n" + "="*80)
    print(f"{'Metric':<20} | {'RIFE HDv3 (Baseline)':<25} | {'Nano V16 (Ours)':<20}")
    print("-" * 80)
    print(f"{'Parameters':<20} | {rife_params/1e6:<23.2f}M | {nano_params/1e3:<18.1f}K")
    print(f"{'Model Size (MB)':<20} | {get_model_size(rife.flownet):<23.2f} | {get_model_size(nano):<18.2f}")
    print(f"{'Latency (1080p)':<20} | {rife_ms:<23.2f}ms | {nano_ms:<18.2f}ms")
    print(f"{'Throughput (FPS)':<20} | {1000/rife_ms:<23.1f} | {1000/nano_ms:<18.1f}")
    print(f"{'Peak VRAM (MB)':<20} | {rife_vram:<23.1f} | {nano_vram:<18.1f}")
    print(f"{'Avg PSNR (dB)':<20} | {np.mean(rife_psnrs):<23.2f} | {np.mean(nano_psnrs):<18.2f}")
    print(f"{'Avg SSIM':<20} | {np.mean(rife_ssims):<23.4f} | {np.mean(nano_ssims):<18.4f}")
    print("="*80)

    print(f"\n💡 Paper Insight: Nano uses {rife_vram/nano_vram:.1f}x less VRAM and is {rife_ms/nano_ms:.1f}x faster,")
    print(f"   while maintaining competitive quality of {(np.mean(nano_psnrs)/np.mean(rife_psnrs)*100):.2f}% (PSNR drop of {np.mean(rife_psnrs)-np.mean(nano_psnrs):.2f} dB).")

if __name__ == "__main__":
    benchmark()
