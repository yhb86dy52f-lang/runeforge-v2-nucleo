# RUNEFORGE V2 CORE - Documentación Oficial
**Fecha:** 2026-10-20 23:08:34
**Auditoría:** 88 HTMLs limpios (sin node_modules/.git/target/dist) + firmware
**Peso Total:** ~11.18 MB | Peso Max: 1.17 MB

## 1. Resumen Ejecutivo
Proyecto consolidado con 3 dominios: **Firmware Pesado (1.1 MB), Dashboard/Panel (0.22 MB) y SPA/Tauri (0.19 MB)**. 
Se detectaron **17 duplicados conceptuales** con misma plantilla base. Se omite movimiento por dependencias.

## 2. Estructura de Carpetas
C:\RUNEFORGE_V2_CORE
├── firmware\ # 4 pesados - Grimorio + Scanner + GPS
│ ├── scannerpro_cyber_visualizer\ # 1.1695 MB - Radar + Fuel + MQTT (29 IDs)
│ ├── grimorio_completo_72_ia.html # 1.1718 MB x2 duplicado
│ └── fusionada_sonar_instalaciones_sepcolgps.html # 0.5072 MB - GPS real
├── public\ # Master y dashboards ligeros
│ ├── index.html # 0.22 MB - Base dashboard
│ ├── simulador.html # 0.2094 MB x3 duplicados
│ └── index_master.html # 10.84 KB - Master generado paso 2
├── runeforge-v2-nucleo\simulador\ # Simulador LMU2630 - 3 copias
├── forja\ # Laboratorio + Dictate Tauri
│ ├── laboratorio.html # 0.2013 MB Dashboard
│ └── dictate-src\ # 2 SPA Tauri reales
├── apps\ # Build outputs
└── docs\dashboard\ # 4 copias COLLAB_DASHBOARD


## 3. Auditoría TOP 20 Real Corregido (con firmware)
| # | MB | Tipo | Ruta |
|---|----|------|------|
| 1 | 1.1718 | Firmware Pesado / Grimorio | `C:\RUNEFORGE_V2_CORE\firmware\grimorio_x5f_completo_x5f_72_x5f_ia.html` |
| 2 | 1.1718 | Firmware Pesado / Grimorio | `C:\RUNEFORGE_V2_CORE\firmware\grimorio_x5f_completo_x5f_72_x5f_ia (1).html` |
| 3 | 1.1695 | Firmware Pesado / Grimorio | `C:\RUNEFORGE_V2_CORE\firmware\scannerpro_cyber_visualizer\scannerpro_cyber_visualizer.html` |
| 4 | 0.5072 | Firmware Pesado / Grimorio | `C:\RUNEFORGE_V2_CORE\firmware\fusionada_x5f_sonar_x5f_instalaciones_x5f_sepcolgps.html` |
| 5 | 0.2203 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador\index.html` |
| 6 | 0.2203 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador\LMU2630_GitHub_Pages_Ready\index.html` |
| 7 | 0.2202 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\public\index.html` |
| 8 | 0.2094 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador\LMU2630_GitHub_Pages_Ready\simulador.html` |
| 9 | 0.2094 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\public\simulador.html` |
| 10 | 0.2094 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador\simulador.html` |
| 11 | 0.2013 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\forja\laboratorio.html` |
| 12 | 0.1998 | SPA / Tauri | `C:\RUNEFORGE_V2_CORE\forja\dictate-src\Dictate-Whisper.html` |
| 13 | 0.1985 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador\LMU2630_GitHub_Pages_Ready\Lmu2630-Sim-Pro-V5.html` |
| 14 | 0.1935 | SPA / Tauri | `C:\RUNEFORGE_V2_CORE\forja\dictate-src\Dictate-Unified.html` |
| 15 | 0.1882 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\firmware\scanner-v72-decoder.html` |
| 16 | 0.1876 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\firmware\forge_x5f_sms_x5f_hub_x5f_mobile.html` |
| 17 | 0.1822 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\firmware\RUNEFORGE_COLLAB_FINAL_CORREGIDO_v1\dashboard\RUNEFORGE_COLLAB_DASHBOARD.html` |
| 18 | 0.1822 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\firmware\dashboard\RUNEFORGE_COLLAB_DASHBOARD.html` |
| 19 | 0.1822 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\docs\RUNEFORGE_COLLAB_FINAL_CORREGIDO_v1\dashboard\RUNEFORGE_COLLAB_DASHBOARD.html` |
| 20 | 0.1822 | Dashboard / Panel | `C:\RUNEFORGE_V2_CORE\docs\dashboard\RUNEFORGE_COLLAB_DASHBOARD.html` |
## 4. Deep Inspector - ScannerPro Visualizer
**Archivo:** firmware\scannerpro_cyber_visualizer.html | 1197.56 KB | 1,226,283 chars

**IDs Reales (29 únicos):**
- Radar: radarCanvas, spectrumCanvas, deviceTableBody, targetMac, targetRssi, targetTime, targetDetails
- Fuel: fuelGaugeCircle, fuelAdc, fuelBatt, fuelLiters, fuelPercentage, fuelTemp
- MQTT: mqttStatusBadge, mqttStatusText
- Tabs: tab-devices, tab-fuel, tab-radar, tab-firmware

**Clases Reales (154 únicas - Tailwind Cyber):**
bg-cyber-500, bg-cyber-bg, border-cyber-border, glass-panel, glow-text, animate-ping, animate-pulse

**Scripts (5 bloques):**
- Script #1: 407KB TEMP:True QR:True
- Script #2: 447KB TEMP:True QR:True ETIQUETA:True DASH:True -> Core iconos Thermometer
- Script #3: 342KB TEMP:True QR:True
- Script #4: 617 chars init
- Script #5: 8161 chars QR:True

**@media print:** 0 bloques - Etiqueta NO está aquí, está en grimorio/fusionada

## 5. Clasificación Real
- Firmware Pesado / Grimorio: 4 archivos (1.17 MB, 0.50 MB) - 60% peso
- Dashboard / Panel: 14 archivos (0.22-0.18 MB) - Patrón dominante APP TABAJO
- SPA / Tauri: 2 archivos (0.19 MB) - Dictate-Whisper/Unified con __TAURI__
- Estático / Docs: 84 archivos en audit 88 inicial (falso, era sin firmware)
- Build Output: 1 archivo dist

## 6. Duplicados Detectados (No movidos por seguridad)
- grimorio_completo_72_ia (1).html = duplicado exacto 1.1718 MB
- simulador/index.html x3 [public, runeforge-v2-nucleo/simulador, LMU2630...]
- simulador.html x3
- RUNEFORGE_COLLAB_DASHBOARD.html x4
- Total 17 con misma plantilla base

## 7. Masters Identificados - Estándar RUNEFORGE
### MASTER 1 - FIRMWARE RADAR [1.1695 MB]
scannerpro_cyber_visualizer.html - Base para radar BLE/WiFi + combustible + MQTT
IDs: radarCanvas, fuelGaugeCircle, deviceTableBody

### MASTER 2 - GPS [0.5072 MB]
usionada_sonar_instalaciones_sepcolgps.html - Único con lat/lng, calamp, lmu2630, sonar

### MASTER 3 - DASHBOARD [0.22 MB]
simulador/index.html / public/index.html - Base ligera GitHub Pages sin base64

### MASTER 4 - SPA TAURI [0.19 MB]
Dictate-Whisper.html, Dictate-Unified.html - Únicas con __TAURI__ / invoke

## 8. Recomendación Inmediata APP TABAJO
1. No mover duplicados (pueden tener referencias backend/Flutter)
2. Usar public\index_master.html como estándar único modular
3. Inyectar: Radar de scannerpro + GPS de fusionada + Dashboard de simulador/index
4. Etiqueta @media print cazar en grimorio - no está en scannerpro
5. Consolidar 4 COLLAB_DASHBOARD en 1 solo en public\

## 9. Reportes Generados
- C:\RUNEFORGE_V2_CORE\reports\html_audit_20261020_225625.json (88 archivos)
- C:\RUNEFORGE_V2_CORE\reports\html_audit_FINAL_20261020.json (TOP 20 real)
- C:\RUNEFORGE_V2_CORE\public\index_master.html (10.84 KB master inicial)
- C:\RUNEFORGE_V2_CORE\public\etiqueta_template_extraida.html (si aplica)
- C:\RUNEFORGE_V2_CORE\public\gps_template_extraido.html (si aplica)

## 10. Validación
- PowerShell 5.1.19041.1 / 7.6.7 OK
- WMI WSearch Running OK
- Origen intacto, sin movimiento - Modo seguro

---
Generado automáticamente por scripts en C:\RUNEFORGE_V2_CORE\scripts\
