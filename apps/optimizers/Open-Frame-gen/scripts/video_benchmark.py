"""
video_benchmark.py — Video File Benchmark for Paper Figures
═══════════════════════════════════════════════════════════════════════════════
Benchmarks frame interpolation quality on video files.
Outputs:
  - PSNR/SSIM metrics
  - Side-by-side comparison images
  - Latency measurements
"""

import os
import sys
import time
import argparse
import cv2
import numpy as np
import torch
import torch.nn.functional as F
from pathlib import Path

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "src"))
from nano import NanoModel

# Try to import RIFE for comparison
try:
    from RIFE_HDv3 import Model as RIFEModel
    RIFE_AVAILABLE = True
except:
    RIFE_AVAILABLE = False


def calc_psnr(img1, img2):
    """Calculate PSNR between two images"""
    mse = np.mean((img1.astype(np.float64) - img2.astype(np.float64)) ** 2)
    if mse == 0:
        return float('inf')
    return 20 * np.log10(255.0 / np.sqrt(mse))


def calc_ssim(img1, img2):
    """Calculate SSIM between two images (simplified)"""
    C1 = (0.01 * 255) ** 2
    C2 = (0.03 * 255) ** 2

    img1 = img1.astype(np.float64)
    img2 = img2.astype(np.float64)

    mu1 = cv2.GaussianBlur(img1, (11, 11), 1.5)
    mu2 = cv2.GaussianBlur(img2, (11, 11), 1.5)

    mu1_sq = mu1 ** 2
    mu2_sq = mu2 ** 2
    mu1_mu2 = mu1 * mu2

    sigma1_sq = cv2.GaussianBlur(img1 ** 2, (11, 11), 1.5) - mu1_sq
    sigma2_sq = cv2.GaussianBlur(img2 ** 2, (11, 11), 1.5) - mu2_sq
    sigma12 = cv2.GaussianBlur(img1 * img2, (11, 11), 1.5) - mu1_mu2

    ssim_map = ((2 * mu1_mu2 + C1) * (2 * sigma12 + C2)) / \
               ((mu1_sq + mu2_sq + C1) * (sigma1_sq + sigma2_sq + C2))

    return float(np.mean(ssim_map))


def load_video_frames(video_path, max_frames=100):
    """Load frames from video file"""
    cap = cv2.VideoCapture(video_path)
    frames = []

    while len(frames) < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(frame)

    cap.release()
    return frames


def benchmark_nano(model, frames, device):
    """Benchmark NanoModel on frame pairs"""
    results = {
        'psnr': [],
        'ssim': [],
        'latency_ms': []
    }

    model.eval()
    with torch.no_grad():
        for i in range(0, len(frames) - 2, 2):
            frame0 = frames[i]
            frame1 = frames[i + 2]
            gt = frames[i + 1]  # Ground truth middle frame

            # Prepare input
            h, w = frame0.shape[:2]

            # Pad to multiple of 32
            pad_h = (32 - h % 32) % 32
            pad_w = (32 - w % 32) % 32

            t0 = torch.from_numpy(frame0).permute(2, 0, 1).float().div_(255.).unsqueeze(0)
            t1 = torch.from_numpy(frame1).permute(2, 0, 1).float().div_(255.).unsqueeze(0)

            if pad_h > 0 or pad_w > 0:
                t0 = F.pad(t0, (0, pad_w, 0, pad_h), mode='reflect')
                t1 = F.pad(t1, (0, pad_w, 0, pad_h), mode='reflect')

            inp = torch.cat([t0, t1], dim=1).to(device).half()

            # Warmup
            if i == 0:
                for _ in range(3):
                    _ = model(inp)
                torch.cuda.synchronize()

            # Time inference
            start = time.perf_counter()
            output = model(inp)
            torch.cuda.synchronize()
            latency = (time.perf_counter() - start) * 1000

            # Convert output
            output = output[:, :, :h, :w]  # Remove padding
            output_np = (output[0].permute(1, 2, 0).cpu().float().numpy() * 255).clip(0, 255).astype(np.uint8)

            # Calculate metrics
            psnr = calc_psnr(output_np, gt)
            ssim = calc_ssim(output_np, gt)

            results['psnr'].append(psnr)
            results['ssim'].append(ssim)
            results['latency_ms'].append(latency)

    return results


def create_comparison_image(frame0, gt, output, frame1, save_path):
    """Create side-by-side comparison image for paper"""
    h, w = gt.shape[:2]

    # Create 2x2 grid
    grid = np.zeros((h * 2 + 10, w * 2 + 10, 3), dtype=np.uint8)

    # Top left: Frame 0
    grid[:h, :w] = frame0
    cv2.putText(grid, "Frame t-1", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

    # Top right: Frame 1
    grid[:h, w+10:] = frame1
    cv2.putText(grid, "Frame t+1", (w + 20, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

    # Bottom left: Ground truth
    grid[h+10:, :w] = gt
    cv2.putText(grid, "Ground Truth (t)", (10, h + 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

    # Bottom right: Our output
    grid[h+10:, w+10:] = output
    cv2.putText(grid, "Our Result (t)", (w + 20, h + 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

    cv2.imwrite(save_path, grid)
    return grid


def create_split_comparison(gt, output, save_path):
    """Create split-screen comparison (left=GT, right=ours)"""
    h, w = gt.shape[:2]
    split = w // 2

    comparison = gt.copy()
    comparison[:, split:] = output[:, split:]

    # Draw dividing line
    cv2.line(comparison, (split, 0), (split, h), (255, 255, 255), 2)
    cv2.putText(comparison, "GT", (split - 80, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
    cv2.putText(comparison, "Ours", (split + 10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)

    cv2.imwrite(save_path, comparison)
    return comparison


def main():
    parser = argparse.ArgumentParser(description='Video Frame Interpolation Benchmark')
    parser.add_argument('--video', type=str, help='Path to input video file')
    parser.add_argument('--dataset', type=str, default=os.path.join(ROOT, 'dataset', 'raw', 'images'),
                        help='Path to dataset images folder')
    parser.add_argument('--weights', type=str, default=os.path.join(ROOT, 'checkpoints', 'nano_v17_best.pth'),
                        help='Path to model weights')
    parser.add_argument('--output', type=str, default='benchmark_results',
                        help='Output directory for results')
    parser.add_argument('--max-frames', type=int, default=100,
                        help='Maximum frames to process')
    parser.add_argument('--save-images', action='store_true',
                        help='Save comparison images')
    args = parser.parse_args()

    # Create output directory
    os.makedirs(args.output, exist_ok=True)

    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"🚀 Video Benchmark on {torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU'}")

    # Load model
    model = NanoModel().to(device).half()
    if os.path.exists(args.weights):
        state = torch.load(args.weights, map_location=device, weights_only=True)
        model.load_state_dict(state, strict=False)
        print(f"✅ Loaded weights from {args.weights}")
    else:
        print(f"⚠️ Weights not found: {args.weights}, using random initialization")

    # Load frames
    if args.video:
        print(f"📹 Loading video: {args.video}")
        frames = load_video_frames(args.video, args.max_frames)
    else:
        print(f"📂 Loading dataset: {args.dataset}")
        img_files = sorted([f for f in os.listdir(args.dataset) if f.endswith('.png')])[:args.max_frames]
        frames = [cv2.imread(os.path.join(args.dataset, f)) for f in img_files]
        frames = [f for f in frames if f is not None]

    print(f"   Loaded {len(frames)} frames")

    if len(frames) < 3:
        print("❌ Need at least 3 frames for interpolation")
        return

    # Run benchmark
    print("\n⏱️  Running benchmark...")
    results = benchmark_nano(model, frames, device)

    # Print results
    print("\n" + "=" * 60)
    print("BENCHMARK RESULTS")
    print("=" * 60)
    print(f"Frames processed: {len(results['psnr'])}")
    print(f"Resolution: {frames[0].shape[1]}x{frames[0].shape[0]}")
    print("-" * 60)
    print(f"Average PSNR: {np.mean(results['psnr']):.2f} dB")
    print(f"Average SSIM: {np.mean(results['ssim']):.4f}")
    print(f"Average Latency: {np.mean(results['latency_ms']):.2f} ms")
    print(f"Throughput: {1000 / np.mean(results['latency_ms']):.1f} FPS")
    print("=" * 60)

    # Save results to CSV
    import pandas as pd
    df = pd.DataFrame(results)
    csv_path = os.path.join(args.output, 'metrics.csv')
    df.to_csv(csv_path, index=False)
    print(f"\n📊 Metrics saved to {csv_path}")

    # Save comparison images
    if args.save_images:
        print("\n🖼️  Saving comparison images...")

        # Select a few representative frames
        indices = [0, len(frames)//4, len(frames)//2, 3*len(frames)//4]
        indices = [i for i in indices if i + 2 < len(frames)]

        model.eval()
        with torch.no_grad():
            for idx, i in enumerate(indices):
                frame0 = frames[i]
                frame1 = frames[i + 2]
                gt = frames[i + 1]

                h, w = frame0.shape[:2]
                pad_h = (32 - h % 32) % 32
                pad_w = (32 - w % 32) % 32

                t0 = torch.from_numpy(frame0).permute(2, 0, 1).float().div_(255.).unsqueeze(0)
                t1 = torch.from_numpy(frame1).permute(2, 0, 1).float().div_(255.).unsqueeze(0)

                if pad_h > 0 or pad_w > 0:
                    t0 = F.pad(t0, (0, pad_w, 0, pad_h), mode='reflect')
                    t1 = F.pad(t1, (0, pad_w, 0, pad_h), mode='reflect')

                inp = torch.cat([t0, t1], dim=1).to(device).half()
                output = model(inp)
                output = output[:, :, :h, :w]
                output_np = (output[0].permute(1, 2, 0).cpu().float().numpy() * 255).clip(0, 255).astype(np.uint8)

                # Save grid comparison
                grid_path = os.path.join(args.output, f'comparison_{idx:02d}_grid.png')
                create_comparison_image(frame0, gt, output_np, frame1, grid_path)

                # Save split comparison
                split_path = os.path.join(args.output, f'comparison_{idx:02d}_split.png')
                create_split_comparison(gt, output_np, split_path)

                print(f"   Saved comparison {idx+1}/{len(indices)}")

        print(f"✅ Comparison images saved to {args.output}/")

    # Summary for paper
    print("\n" + "=" * 60)
    print("PAPER-READY SUMMARY")
    print("=" * 60)
    param_count = sum(p.numel() for p in model.parameters()) / 1000
    print(f"Model Parameters: {param_count:.1f}K")
    print(f"PSNR: {np.mean(results['psnr']):.2f} ± {np.std(results['psnr']):.2f} dB")
    print(f"SSIM: {np.mean(results['ssim']):.4f} ± {np.std(results['ssim']):.4f}")
    print(f"Latency: {np.mean(results['latency_ms']):.2f} ± {np.std(results['latency_ms']):.2f} ms")
    print("=" * 60)


if __name__ == "__main__":
    main()
