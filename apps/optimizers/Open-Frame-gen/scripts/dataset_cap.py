''' A simple screen and input capture tool for creating datasets for our project's dataset.
    - Captures screen using DXCam '''
'-key issues as of now this doesnt support the following issues '
'-1. Multiple monitors (only captures primary monitor)'
'-2. Controller inputs (only captures mouse and keyboard)'
import os
import time
import csv
import threading
import queue
import cv2
import dxcam
import numpy as np
from pynput import mouse, keyboard

# --- CONFIG ---
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAVE_DIR = os.path.join(ROOT, "dataset", "raw")
TARGET_FPS = 30  #captures at 30 fps (as of now to make sure we dont have too much data)
STOP_KEY = keyboard.Key.f12 # press F12 to stop recording
'30 fps might have been too much data, changed to 15 fps'
# --- GLOBAL STATE ---
write_queue = queue.Queue()
running = True
mouse_lock = threading.Lock()
current_mouse = {"dx": 0, "dy": 0, "keys": set()}
last_mouse_pos = None

# --- PASSIVE LISTENERS ---
def on_move(x, y):
    global last_mouse_pos
    with mouse_lock:
        if last_mouse_pos is not None:
            current_mouse["dx"] += x - last_mouse_pos[0]
            current_mouse["dy"] += y - last_mouse_pos[1]
        last_mouse_pos = (x, y)

def on_press(key):
    try:
        k = key.char
    except AttributeError:
        k = str(key).replace("Key.", "")

    if key == STOP_KEY:
        global running
        running = False
        return False

    with mouse_lock:
        current_mouse["keys"].add(k)

def on_release(key):
    try:
        k = key.char
    except AttributeError:
        k = str(key).replace("Key.", "")
    with mouse_lock:
        current_mouse["keys"].discard(k)

# --- DISK WRITER ---
def writer_worker():
    os.makedirs(f"{SAVE_DIR}/images", exist_ok=True)
    f = open(f"{SAVE_DIR}/log.csv", "w", newline="")
    writer = csv.writer(f)
    writer.writerow(["frame_id", "timestamp", "dx", "dy", "keys"])

    while True:
        item = write_queue.get()
        if item is None: break

        fid, ts, frame, dx, dy, keys = item

        # Save Image (JPG)
        cv2.imwrite(f"{SAVE_DIR}/images/{fid:06d}.jpg", frame)

        # Save Log
        writer.writerow([fid, ts, dx, dy, "|".join(keys)])
        write_queue.task_done()

    f.close()
    print("Writer Thread Finished.")

# --- MAIN LOOP ---
def main():
    print("Initializing DXCam...")
    # output_color=BGR is CRITICAL for OpenCV compatibility
    camera = dxcam.create(output_idx=0, output_color="BGR")

    # Start Listeners
    m_listener = mouse.Listener(on_move=on_move)
    k_listener = keyboard.Listener(on_press=on_press, on_release=on_release)
    m_listener.start()
    k_listener.start()

    # Start Writer
    t_writer = threading.Thread(target=writer_worker)
    t_writer.start()

    print(f"RECORDING. Switch to game (Borderless Window!). Press F12 to Stop.")

    camera.start(target_fps=TARGET_FPS, video_mode=True)
    frame_id = 0

    try:
        while running:
            # 1. Grab Frame (Blocks until new frame arrives)
            frame = camera.get_latest_frame()
            timestamp = time.time()

            # 2. Grab & Reset Inputs
            with mouse_lock:
                dx, dy = current_mouse["dx"], current_mouse["dy"]
                keys = list(current_mouse["keys"])
                current_mouse["dx"] = 0 # Reset delta for next frame
                current_mouse["dy"] = 0

            # 3. Push to Background Thread
            write_queue.put((frame_id, timestamp, frame, dx, dy, keys))

            frame_id += 1
            if frame_id % 100 == 0:
                print(f"Captured: {frame_id} frames...", end="\r")

    except KeyboardInterrupt:
        pass
    finally:
        camera.stop()
        m_listener.stop()
        k_listener.stop()
        write_queue.put(None) # Kill signal
        t_writer.join()
        print(f"\nDone. Saved {frame_id} frames to {SAVE_DIR}")

if __name__ == "__main__":
    main()
