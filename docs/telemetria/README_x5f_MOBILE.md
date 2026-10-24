# SEPCOLGPS NEXUS v20 - MODO DESCENTRALIZADO (SOLO TERMUX)

## Que descargar (3 archivos)
1. index.html (20KB, todo inline, sin npm)
2. icon.png (512x512)
3. build.sh (script maestro)

## Pasos sumamente especificos - Desde cero

### PASO 0: Abrir Termux (primera vez)
```
pkg update -y
pkg install openjdk-17 aapt2 -y
pkg install termux-tools -y
termux-setup-storage
```

### PASO 1: Crear carpeta
```
mkdir -p ~/public/DECODE
cd ~/public/DECODE
```

### PASO 2: Descargar los 3 archivos
En esta app de Meta AI, descarga:
- index.html -> Mover a /data/data/com.termux/files/home/public/DECODE/
- icon.png -> Mover a misma carpeta
- build.sh -> Mover a misma carpeta

O si usas curl desde Termux (si subiste a tu host):
```
cd ~/public/DECODE
# coloca los archivos aqui
```

Verifica:
```
ls -lh
# debe mostrar: index.html, icon.png, build.sh
```

### PASO 3: Dar permisos y correr
```
chmod +x build.sh
bash build.sh
```

El script hace:
1. Limpia apk_build
2. Copia index.html + icon.png a assets
3. Crea AndroidManifest.xml
4. Crea MainActivity.java con fix móvil
5. Descarga android.jar (solo primera vez, 4MB)
6. Compila Java -> classes.dex
7. Empaqueta con aapt2
8. Firma con keystore (genera my-release-key.keystore solo primera vez)
9. Copia APK a /sdcard/Download/SEPCOLGPS_MOBILE.apk
10. Abre instalador

### PASO 4: Instalar
Cuando aparezca el instalador de Android, dale Instalar.

Listo: App SEPCOLGPS NEXUS v20 MOBILE aparece en tu cajón.

### Estructura final (solo este dispositivo)
```
~/public/DECODE/
├── index.html (20KB)
├── icon.png
├── build.sh
├── my-release-key.keystore (generado auto)
└── apk_build/ (temporal, se borra cada build)
```

Sin node_modules. Sin package.json. Sin PC.
