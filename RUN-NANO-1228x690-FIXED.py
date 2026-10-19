"""
RUN_NANO_1228x690_FIXED.py - Launcher para tu monitor 1228x690
Ponlo en C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui\ y corre:
python ui/RUN_NANO_1228x690_FIXED.py
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import dxcam
import torch

print("[RUNEFORGE FIX] Monitor detectado 1228x690 - parcheando dxcam para auto fullscreen")
print("[FIX] Forzando region=None para que detecte tu resolucion real")

# Fix affinity error - parchea la funcion que da error
try:
    import psutil
    orig_cpu_affinity = psutil.Process.cpu_affinity
    def safe_affinity(self, cpus=None):
        if cpus is None:
            try:
                return orig_cpu_affinity(self)
            except:
                return []
        try:
            # Filtra None
            cpus = [c for c in cpus if c is not None]
            if not cpus:
                return []
            return orig_cpu_affinity(self, cpus)
        except:
            return []
    psutil.Process.cpu_affinity = safe_affinity
    print("[FIX] Affinity parcheado")
except Exception as e:
    print(f"[WARN] No se pudo parchar affinity: {e}")

# Intenta crear cam con region=None (fullscreen auto)
try:
    print("Creando cam con region=None...")
    cam = dxcam.create(output_color="BGRA", max_buffer_len=1)
    print(f"[OK] DXCAM creado: {cam}")
    print("[OK] Iniciando captura 2 seg...")
    cam.start(region=None)
    import time
    time.sleep(1)
    frame = cam.get_latest_frame()
    if frame is not None:
        print(f"[OK] Frame capturado: {frame.shape} - tu 1228x690 funciona!")
    else:
        print("[WARN] Frame None, pero cam no crasheó")
    cam.stop()
    print("[OK] Prueba de DXCAM pasó. Ahora puedes correr ui_overlay.py original")
except Exception as e:
    print(f"[FAIL] Error: {e}")
    import traceback
    traceback.print_exc()
    print("\n[SOLUCION] Usa el modo sin overlay:")
    print("cd C:\\RUNEFORGE_V2_CORE\\apps\\optimizers\\Open-Frame-gen")
    print("python -c \"import dxcam; c=dxcam.create(output_color='BGRA'); c.start(); import time; time.sleep(3); print('OK')\"")
