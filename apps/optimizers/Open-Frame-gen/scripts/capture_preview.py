"""
capture_preview.py - Capture NANO Preview window for paper figures
"""

import win32gui
import cv2
import numpy as np
import os
from datetime import datetime
from PIL import ImageGrab

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def list_all_windows():
    windows = []
    def callback(hwnd, _):
        if win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            if title:
                rect = win32gui.GetWindowRect(hwnd)
                windows.append((hwnd, title, rect))
        return True
    win32gui.EnumWindows(callback, None)
    return windows

def capture_region(rect):
    """Capture screen region"""
    left, top, right, bottom = rect
    if right <= left or bottom <= top:
        return None
    try:
        img = ImageGrab.grab(bbox=(left, top, right, bottom))
        return cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    except Exception as e:
        print(f"Capture error: {e}")
        return None

def main():
    print("=" * 50)
    print("NANO Preview Capture Tool")
    print("=" * 50)

    os.makedirs(os.path.join(ROOT, "figures", "captures"), exist_ok=True)

    # Find windows with NANO in title
    windows = list_all_windows()
    nano_windows = [(h, t, r) for h, t, r in windows if 'NANO' in t.upper()]

    if not nano_windows:
        print("\n❌ No NANO windows found!")
        print("\nAll visible windows:")
        for h, t, r in windows[:15]:
            print(f"  - {t[:50]}")
        return

    print("\nFound NANO windows:")
    for i, (h, t, r) in enumerate(nano_windows):
        w = r[2] - r[0]
        h = r[3] - r[1]
        print(f"  [{i}] {t} ({w}x{h})")

    # Pick the preview window or largest one
    target = None
    for h, t, r in nano_windows:
        if 'Preview' in t:
            target = (h, t, r)
            break
    if not target:
        target = nano_windows[0]

    hwnd, title, rect = target
    print(f"\n✅ Using: {title}")
    print(f"   Rect: {rect}")

    # Adjust for window chrome
    left, top, right, bottom = rect
    left += 1
    top += 1
    right -= 1
    bottom -= 1
    adjusted_rect = (left, top, right, bottom)

    print(f"\nPress 'c' to capture, 'q' to quit")
    print(f"Make sure the window is visible (not minimized)!")

    capture_count = 0

    while True:
        img = capture_region(adjusted_rect)

        if img is None or img.size == 0:
            # Try full rect
            img = capture_region(rect)

        if img is None or img.size == 0:
            print("Cannot capture - is window visible?")
            key = cv2.waitKey(1000) & 0xFF
            if key == ord('q'):
                break
            continue

        h, w = img.shape[:2]
        scale = min(800/w, 600/h, 1.0)
        preview = cv2.resize(img, (int(w*scale), int(h*scale)))
        cv2.imshow("Preview - 'c'=capture, 'q'=quit", preview)

        key = cv2.waitKey(100) & 0xFF

        if key == ord('c'):
            capture_count += 1
            ts = datetime.now().strftime("%H%M%S")
            filename = os.path.join(ROOT, "figures", "captures", f"nano_{ts}.png")
            cv2.imwrite(filename, img)
            print(f"✓ Saved: {filename}")

        elif key == ord('q'):
            break

    cv2.destroyAllWindows()
    print(f"\nCaptured {capture_count} frames.")

if __name__ == "__main__":
    main()
