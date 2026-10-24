# TELEMETRÍA GPS - CALAMP - BITÁCORA MAESTRA COMPLETA
## Nesthor CV - Torreón - Proyecto CT Termo - 2026-10-20

> Este MD integra ABSOLUTAMENTE TODO lo trabajado en esta conversación + tu Drive "Ingeniería de GPS CalAmp" + diagnósticos de campo + apps desarrolladas para tu Motorola con Termux

---

## ÍNDICE
1. [Arquitectura CalAmp LMU - De tu Drive](#1-arquitectura-calamp-lmu---de-tu-drive)
2. [Mapeo de Pines y Hardware](#2-mapeo-de-pines)
3. [Metrología y Sensores](#3-metrologia)
4. [Protocolo LM Direct](#4-lm-direct)
5. [Motor PEG](#5-peg)
6. [J1939 y jPOD / EdgeCore](#6-j1939)
7. [Configuración AT y SMS](#7-configuracion)
8. [Trabajo de Campo - 6 Unidades CT Analizadas](#8-campo)
9. [Decodificación HEX !r4 - Hallazgo 0x3E70=15984](#9-hex)
10. [Sensores 4 Hilos Rojo Azul Negro Blanco](#10-sensores-4-hilos)
11. [Prueba con Multímetro y Conexión Correcta](#11-multimetro)
12. [Herramientas Desarrolladas - Dashboards y APK](#12-herramientas)
13. [Archivos Entregados](#13-archivos)

---

## 1. ARQUITECTURA CALAMP LMU - DE TU DRIVE

**Fuente:** Tu Google Doc `Ingeniería de GPS CalAmp` (ID: 1F9kFgPcKI1Zsc2qm6nqh5Jo2ic7dxWV2NHp0MU6iOGI)

La infraestructura de telemetría de CalAmp es un ecosistema robusto de gestión de flotas y telemática de borde (edge telematics). A diferencia de rastreadores cerrados "dumb terminals", la serie LMU (Location and Messaging Unit) y EdgeCore están diseñadas bajo computación distribuida - ejecutan lógicas condicionales complejas, interactúan con redes multiplexadas y auditan sistemas analógicos sin validación continua del servidor.

**Evolución:** 8 y 32 bits (LMU-2030, 2630, 3030) hasta Linux EdgeCore (LMU-3640, 4230, 4350, 5541)

**Especificaciones Ambientales:**
- Grado industrial LMU-4350/5541: -40°C a +60°C con alimentación primaria, -30°C a +75°C con batería interna LiFePO4/LiPo
- IP67, MIL-STD 202G, 810F, SAE J1455 (Load Dump)
- Consumo 12V/24V (7-32VDC tolerancia):
  - Activo LTE CAT-1/CAT-M1/HSPA + GNSS: 60-100mA
  - Radio-Active Sleep (módem latente): 15-25mA
  - Deep Sleep (solo micro despierta por acelerómetro/ignición): <600µA (0.6mA)

---

## 2. MAPEO DE PINES

### LMU-26x0/27x0 (5C908) - 20 pines

| Pin | Señal | Color Estándar | Tipo | Función |
|-----|-------|----------------|------|---------|
| 1 | GND | Negro | Tierra | Retorno chasis |
| 2 | OUT-1 | Verde | Salida | Starter Disable Relay Driver 150mA Open Collector |
| 3 | IN-1 | Azul | Entrada | Digital genérico |
| 8 | IN-0 (Ignición) | Blanco | Entrada Digital | Ignición, sesgada a bajo siempre |
| 4 | ADC-1 | Rosa | Analógica | 0-30VDC ±0.1V |
| 17 | 1BB Data | Blanco/Azul | Bus Datos | 1-Wire temp e iButton |
| 9 | VDD | Naranja | Salida | Referencia 20-25mA max |
| 14 | VCC | Rojo | Potencia | 9-30VDC primaria |
| 15 | GND | Negro | Tierra | Primaria |

### LMU-4250 - 34 pines

| Pin | Señal | Color | Tipo |
|-----|-------|-------|------|
| 1 | VIN | Rojo | Power |
| 2 | GND | Negro | Ground |
| 3 | INPUT 0 Ignición | Blanco | Input |
| 4 | ADC1 | Rosa | Input |
| 14 | INPUT 1 | Azul | Input |
| 21 | 1BB_T_DATA | Verde/Negro | Output |
| 22 | 1BB_GND | Negro | Ground |
| 23 | 1BB_R_DATA | Naranja/Negro | Input |
| 31 | ADC2 | Negro/Rojo | Input |
| 32 | ADC3 | Blanco/Rojo | Input |

**IN-0 siempre es ignición, bias bajo.** IN-1 a IN-7 bias alto/bajo configurable vía S-Register 158.

**ADC internos:** ADC6/7 = antena GPS, ADC8 = temp interna micro, ADC10 = batería interna. ADC1-5 externos para potenciómetros, presión, nivel líquidos.

**Acelerómetro 3 ejes:** mapeado como entrada discreta wake-up. Detecta 0.225G aceleración agresiva, 0.25G frenada brusca, colisiones.

---

## 3. METROLOGÍA ANALÓGICA Y CALIBRACIÓN

Desafío: medir combustible con sensores Escort TD-500/TD-BLE. Relación ADC bruto (0-4095 12bits) a litros no lineal en tanques cilíndricos horizontales y D-Shape (0-15% y 85-100% no lineal).

Solución: **Spline Cúbico Monotónico PCHIP o LOESS**, no interpolación lineal. Tablas densas de hasta 100 puntos, concentrando resolución en extremos para compensar cabezas torisféricas y bafles. Filtrado con promedios móviles para descartar sloshing.

En tu caso CT: no es combustible, es temperatura. Pero mismo principio: `accum_2` y `accum_3` van a Wialon con fórmula `const1.8` y `const32` = `(C*1.8)+32` = °F.

---

## 4. LM DIRECT - PROTOCOLO CAPA APLICACIÓN

Binario propietario sobre UDP para minimizar latencia y planes M2M. Big Endian (Network Byte Order).

**Cabecera dinámica:** Bit 7 del primer byte = Options Header presente.

| Bit Options | Campo | Descripción |
|-------------|-------|-------------|
| 0 | Mobile ID | ESN 10 dígitos en 5 bytes Packed BCD |
| 1 | Mobile ID Type | ESN/IMEI/IMSI |
| 2 | Authentication Word | 4 bytes param 1283 |
| 3 | Routing | Gateway |
| 4 | Forwarding | Redirigir a IPv4/puerto alterno |
| 5 | Response Redirection | ACK a otra dirección |

**Service Type:** 0x01 = Acknowledge Request (congelado en memoria hasta ACK, reintento)

**Message Types:**
- **1 Acknowledge:** ACK red
- **2 Event Report:** Núcleo telemetría. Trigger, Time-of-Fix, entradas digitales, Fix GPS (lat/lon/alt/vel/rumbo), AccumList (32 bits acumuladores)
- **5 Application Message:** Respuestas AT remotas
- **10 Mini Event Report:** Comprimido sin alt/sats, ideal alta frecuencia
- **11,12,14 User Messages:** Túnel serial opaco 848 bytes para MDT/Garmin

---

## 5. PEG - PROGRAMMABLE EVENT GENERATOR - CEREBRO

Máquina de estados asíncrona, edge autonomy. Evalúa hardware, buses, cobertura sin servidor.

**PEG1:** 75-150 eventos concurrentes. **PEG2 (EdgeCore Linux LMU-1300/3640/4350):** ilimitado multi-hilo.

**Evento PEG:** Almacenado desde Parámetro 512. 3 pilares: Triggers + Conditions + Actions (cada uno con Code y Modifier)

**Triggers comunes:**
- 61 Update End: fin OTA firmware/config
- 67 VIN Decode Status: Mod 1 descubrimiento genérico, Mod 3 VIN OK
- 73 Server VIN Processing: Mod 0 falla remota, 17-20 Bus Off/Error Passive

**Conditions:** compuertas lógicas AND/OR/NOT. Ej: bloquear Motion si ignición ON para solo alertar Towing cuando apagado.

**Actions:**
- 1 Send Report: empaqueta Message Type 2 UDP
- 44 Unacknowledged Report: sin esperar ACK
- 49 Update Firmware/Script: conexión CTC/PULS, mod 129
- 70 Hard Reboot: watchdog
- **93 Push Temp to Accumulator:** DS18B20 1-Wire a accum designado por mod
- 131 Generate LMU Event: para Hosted Apps vía CMF
- 144 Debug Logging Control: mod0 tarball, mod1 SPI Flash trace, mod2 subida remota

**Timers:** 16 timers 0-15 One-Shot/Recurring. Debounce param 258: exige velocidad sostenida >100km/h por tiempo antes de disparar, elimina GPS drift.

**Accumulators:** 32 bits 0-4294967296. Odómetro virtual satelital, horómetro, idle hours. Voltajes analógicos. Bitmask accumulator.exceed.threshold.

**Time-Distance Profiles:** Param 262 tiempo seg, 263 distancia metros, 264 heading. Ej: PARAM 265,0,300 y 262,0,900 = OR 15min o distancia, resetea contadores tras TX.

---

## 6. J1939 Y jPOD / EDGECORE LINUX

**jPOD/vPOD:** cortafuegos galvánico y filtro traducción. Escucha promiscua pasiva sobre J1939 CAN bus ECU, filtra PGNs/SPNs irrelevantes, captura consumo, temp refrigerante, presión aceite, RPM, DTCs. Transfiere a LMU-4230 vía serial/VBUS, PEG distribuye a Accumulators. Algunas versiones BLE a tablets Android cabina (MDT) para HOS/ELD compliance.

**EdgeCore Linux:** PMR y CMF APIs

**PMR (PEG Message Routing):** System V IPC Linux, 2 colas:
- **PegTrig Queue:** inyección asincronía. Binario externo ensambla PMR_CLIENT_PEG_CMD PMR_CMD_PEG_TRIGGER Tipo 5, demonio CalAmp lo procesa como sensor hardware
- **SndMsg Queue (User Messaging):** pasadizo seguro, elude sockets. PMR_CMD_UMSG Tipo 6, encapsula en User Message Type 11/12/14 via APN securizado. Colas sobreviven a crash, debe releer memoria compartida tras reinicio.

**CMF (CalAmp Mobile Framework):** JAR Android MDT. Clases CmfPegAction, CmfPegTrigger, Intents ACTION_SEND_PEG_ACTION, ACTION_GENERATE_PEG_TRIGGER. Botón táctil conductor invoca Acción 13 reinicio timer.

**BLE Keyfobs:** Discovery State Machine balizas Advertisement. PEG dispara si MAC Bluetooth Peer Address autenticada, previene arranque sin llavero.

---

## 7. CONFIGURACIÓN AT Y SMS - DE TU DRIVE

**Serial:** 115200 8N1, prefijo AT$APP

| Etapa | Comando | Explicación |
|-------|---------|-------------|
| Factory Reset | AT#FACTORY | Purga PEG corruptos |
| APN | AT$APP GPRS CONTEXT 0 "apn" + PARAM 2314,0,"user" 2315 | PAP/CHAP |
| Inbound 8/16bits | PARAM 2319,0,IP + 769,0,4763 | IP destino |
| Inbound 32bits EdgeCore | PARAM 768,0,IP + 769 | IP resoluble |
| Supresión Auto-Aprov | PARAM 1024,35,1,1 | Evita re-inyección APN por IMSI |
| Reboot OTA | PEG ACTION 70 0 | Commit ROM + PDP IP |
| Descarga PULS/CTC | PEG ACTION 49 129 | Socket efímero dm.calamp.com:20500 |

**YMODEM:** ATDSCFG (.csv config) o ATDNLD (.bin firmware) + AppendCRC16toBin.exe

**SMS out-of-band (!R prefix):**

| SMS | Equiv | Función |
|-----|-------|---------|
| !R0 / !r0 | Ping Estado | Resumen GPS, celular, APN |
| !R1,2306,0,apn !RP | Write Parameter | Escribe memoria: IPs, puertos, timers (PARAM 262) |
| !R3,70,0 | Action Trigger | Soft-Reboot FSM = PEG 70 0 |
| !R3,49,129 | PULS/CTC | Contacto emergencia nube gestión |
| !R3,1,255 | Send 255 | Localización inmediata evento 255 |
| !r4 | Read Accumulators | Dump PEG HEX largo (tu caso) |
| !ra !r3,70,0 | ADC Text | #ADCO: 11248 mV ... |

**Seguridad:** Param 1282 Host Access Lists IP/SMS autorizados, Param 1283 Primary Port Password 4 bytes en Options Header (DROP si no). Si activas 1283 anulas PULS. Param 2177 AT password cifra RS-232 físico, requiere S171.

**S-Registers:**
- 120/150: perfiles comunicación, drivers, baud rate radio externa Iridium/Motorola iDEN
- 132: paridad, data bits, stop bits seriales
- 155 bit0: suprime/permite Auto-Aprovisionamiento por IMSI
- **171: Power Management. Bit2 despejado apaga LTE/GPS en Normal Sleep. ATS171=65 energiza 1-Bit Bus para DS18B20 e iButton**
- 174: Moving Filter HDOP, bloquea reportes desplazamiento si HDOP decae, esteriliza saltos multipath bajo rascacielos/cobertizos

**Troubleshooting:**
- LED verde fijo 2-3min = fix 3D GPS
- LED naranja sin destellos = IP adquirida APN
- AT$APP DEBUG ON = volcado negociación GPRS cruda
- at$app dns maint = DNS lookup dm.calamp.com -> debe devolver 18.205.15.12 si no filtrado VPN Carrier
- ATIS = secuencias inb(0) 137.83.51.39:4763 tabla ruteo

---

## 8. TRABAJO DE CAMPO - 6 UNIDADES CT

**Plataforma:** Wialon rastreo.tgarzaleal.com / 94.130.84.182:20924 LMD APP2:REV12335-REL / REV10979-REL

**Datos crudos ejemplo:**
```
rssi=-57, hdop=0.7, unit_status=0, event_index=21, event_code=50, accum_0=11369, accum_1=4070, accum_2=15984, accum_3=15984, accum_4=15984, accum_5=15984, report_type=2, seq_num=1, host=200.68.152.100:20924, I/O=6/0
```

- rssi -55 a -90, hdop 0.6-1.0 3D-RTIME 16-20 sats
- event 6/10 periódico 10min, 3/1 ign ON, 0/0 OFF, 21/50 power-up cambio host
- I/O 6/0=110 OFF, 7/0=111 ON, 26/0=11010 puerta
- accum_0 ADCO 11248-11430mV 11.2-11.4V, accum_1 ADC5 4068-4070mV 4.06V, accum_2-5 15984 FALLA

**Sensores Wialon:**
- Ignición in1 motor Ence...
- Voltaje Unidad accum_0 V
- Voltaje GPS accum_1 V
- Motor in2
- Temperatura accum_2 °C + Temperatura F personalizado °F const32 + const1.8 = (C*1.8)+32
- Temperatura 2 accum_3 + F2 + Validador Temp const1.8

**Unidades detalladas:**
- **CT199 FALLA DOBLE** MID 4672144079 APP:445 8.7b COM:-87 DA. INTERNET.ITELCEL.COM GPS:3D-RTIME 17 INP:0000000000000111 11.2V ESN - HEX: E4672144079FFFFFF0100006AD7AD6F6AD7AD6F0F39DD9EC24A588B00000002005C11000014FFAB8F070700FFFF0400002C0E00000FE400003E7000003E70 / E4672144079FFFFFF0100006AD7B0E06AD7B0E00F39DBB9C24A548500000002001912000014FFA88F080600FFFF0400002CA600000FE400003E7000003E70 - 2x 3E70
- **CT227 BUENO RESIDUAL** MID 7000276162 12.4V APP:445 8.7b COM:-90 DA. internet.itelcel.com GPS:3D-DIFF 19 INP:0000000000000110 - HEX: E7000276162FFFFFF0100006AD7B38D6AD7B38D0F39E11FC24A4A2E00000000008213020014FFA58F060600FFFF0400002FF900000FE60000001C000003E70 - 1x 3E70 + 01C0=448=44.8C OK
- **871 102 5254 BUENO PERFECTO** MID 4672124239 12.5V GPS:3D-RTIME 20 INP:0000000000000110 - HEX: E4672124239FFFFFF0100006AD7B3A56AD7B3A50BF446EEC4CF904400000000004B14000014FFAA8F060600FFFF04000030B000000FF60000010300000123 - 0x 3E70, termina 0123=291=29.1C
- **CT256 FFFF** MID 7000275353 14.0V GPS:3D-DIFF 20 INP:0000000000100101 - HEX: E7000275353FFFFFF0100006AD7B3A46AD7B3A40BF34AFFC4D6E8BC00000000004B15020014FFA08F062500FFFF04000036DC00000FE0FFFFFFECFFFFFFF - FFFF deshabilitado
- **CT194 FFFF** MID 4672133919 13.5V GPS:3D-DIFF 19 APP:445 8.6l - HEX: E4672133919FFFFFF0100006AD7B38A6AD7B3890F658243C441928A00000002013913020014FFA08F082500FFFF04000034D800000FF2FFFFFF6AFFFFFF3F - FFFF

**INB:** 94.130.84.182:20924 LMD
**RG:** -86 DA. 10.115.225.80 20510 INTERNET.ITELCEL.COM M: dm.calamp.com 20500 I: 94.130.84.182 20924 (intercambio IP)

---

## 9. DECODIFICACIÓN HEX !r4 - HALLAZGO 0x3E70

Todos HEX 125 chars impar (falta 0 al inicio). Al limpiar y convertir a uint16 BE cola 10:

- 2C0E=11278 11.27V, 2CA6=11430 11.43V, 2FF9=12281 12.28V~12.4V, 30B0=12464 12.46V~12.5V, 34D8=13528 13.5V, 36DC=14044 14.04V
- 0FE4=4068 4.06V GPS, 0FE6=4070
- 03E70=15984 FALLA circuito abierto Dallas
- FFFF=65535 accum deshabilitado PEG
- 01C0=448 44.8C, 0123=291 29.1C lectura buena

**Lógica app:**
```
c_3E70 = count 0x3E70
c_FFFF = count 0xFFFF
if c_3E70>=2: FALLA_DOBLE_TERMO ROJO
elif c_3E70==1: FALLA_SIMPLE_RESIDUAL AMARILLO (CT227)
elif c_FFFF>=2 and c_3E70==0: OK_DESHABILITADO AZUL (CT256/CT194)
else: BUENO_PERFECTO VERDE (871)
```

Voltajes: uint16 10000-16000 = volt unidad /1000, 3500-5000 = volt GPS.

---

## 10. SENSORES 4 HILOS - COLORES

**Tu caso:** Rojo, Azul, Negro, Blanco + Negro extra (2 negros común)

**Según manual CalAmp LMU-26xx/27xx y LMU-4250 y doc tracking.sknasolutions.com:**

| Color Sensor | Función CalAmp | Conexión CalAmp |
|--------------|----------------|-----------------|
| BLANCO | DATA sonda 1 | Pin 17 White/Blue 1BB-D |
| AZUL | ENABLE / DATA2 sonda 2 | También a Pin 17 White/Blue 1BB-D (mismo bus) |
| NEGRO x2 | GROUND común | Pin 1 Black GND + Pin 16/22 Black 1BB-GND - los 2 negros juntos |
| ROJO | OUT / VCC | Pin 9 Orange VDD 20-25mA max - Alimentación 3.3-5V |

**Si solo usas negro negro blanco azul sin rojo:** modo parásito, inestable, causa 15984 intermitente.

**Centro Datanab:** hub de 2 sondas DS18B20 en una manguera. Rojo común VCC, Negro común GND, Blanco Data1, Azul Data2.

**S171=65** obligatorio para habilitar bus.

**PEG:** ACTION 93 0 -> temp0 a accum0, 93 1 -> temp1 a accum1, etc. Si no, Wialon se queda en 15984 aunque sonda esté bien.

---

## 11. PRUEBA CON MULTÍMETRO - PROCEDIMIENTO CAMPO

**Desconectado, Ω 20k, batería CT quitada:**
- Negro-Negro: 0Ω (mismo)
- Blanco-Negro: ~10k-15kΩ a 25°C si NTC, o OL si Dallas buena. OL = cable trozado manguera corrugada chasis-caja (90% fallas)
- Azul-Negro: igual, ~10k-15kΩ o OL
- Blanco-Azul: OL, si 0Ω corto entre datas
- Rojo-Negro: >50kΩ o OL, si 0Ω sensor quemado

**Conectado, VDC 20V, LMU prendido:**
- Rojo-Negro: 3.3-5V fijos. 0V = sin alimentación bus, revisar S171
- Blanco-Negro: 3.5-4.8V fluctuando (brinco 3.6-4.2V) = comunicación 1-Wire OK. 0V fijo = bus a tierra. 5V fijo sin brinco = no interrogado, S171 mal o PEG 93 no ejecutado
- Azul-Negro: igual fluctuante

**Si ves fluctuación bonita pero Wialon 15984:** es PEG, no cable. Revisar `AT$APP PEG ACTION 93`.

**CT227 BUENO con 1x 3E70:** Blanco-Negro OK 01C0=448=44.8C, Azul-Negro OL = una sonda trozada, otra buena. Por eso operativo con 1 sonda.

---

## 12. HERRAMIENTAS DESARROLLADAS PARA MOTOROLA ANDROID + TERMUX

### A) CT Thermo Lab Pro v3 Dashboard
`ct_thermo_lab_pro_agentic_artifact_2_216678b4de69.html`
- Gauges circulares volt unidad/GPS con semáforo
- Camión SVG con sondas S1/S2 iluminadas verde/rojo/gris según decode
- Gráficas barras comparativa 6 casos voltajes
- Dona estados BUENO/FALLA/DESHABILITADO
- Timeline accum tail 10
- Tabla comparativa 6 casos
- JSON normalizado + recomendación

### B) CT Thermo Lab MOBILE APK PWA
`CT_Thermo_Lab_Pro_MOBILE.html`
- Instalable: Chrome -> ⋮ -> Agregar a pantalla principal / Instalar app
- Botón 📋 Pegar del portapapeles (navigator.clipboard.readText)
- Optimizado campo, offline, sin internet
- Botón grande DECODIFICAR Y VER CAMIÓN

### C) Decoders Python Termux
- `calamp_decoder.py` v1 básico
- `calamp_decoder_v3.py` v3 con 6 casos, conteo 3E70/FFFF, voltajes
```bash
python calamp_decoder_v3.py "E7000276162FFFFFF0100006AD7B38D..."
termux-sms-list -l 30 | grep -oE "[0-9A-F]{120,}" | tail -1 | xargs python calamp_decoder_v3.py
```

### D) Scripts Termux Auto Lector
- `termux_ct199.sh` v1
- `termux_ct199_v2.sh` v3
```bash
chmod +x termux_ct199_v2.sh
./termux_ct199_v2.sh
termux-sms-send -n 871XXXXXXX "!r4"
```

**Instalación Termux:**
```
pkg install python termux-api
# Instalar app Termux:API de F-Droid
```

---

## 13. ARCHIVOS ENTREGADOS Y DRIVE

**Locales en /mnt/data:**
- `telemetria_gps_sensores_equipos.md` - este archivo maestro
- `CT_Thermo_Lab_Pro_MOBILE.html` - APK PWA móvil
- `ct_thermo_lab_pro_agentic_artifact_2_216678b4de69.html` - Dashboard v3
- `calamp_decoder.py`, `calamp_decoder_v3.py`
- `termux_ct199.sh`, `termux_ct199_v2.sh`
- Fotos originales: `photo5773612752355813991.jpeg` CT227 BUENO, `photo3276963391917084735.jpeg` 871, `photo4899604335657024424.jpeg` CT256, `photo2571428829241470856.jpeg` CT194, más CT199 fallas

**Drive encontrados (10 archivos):**
- `Ingeniería de GPS CalAmp` (ID 1F9kFgPcKI1Zsc2qm6nqh5Jo2ic7dxWV2NHp0MU6iOGI) - Doc maestro 23k bytes integrado arriba
- `Presentacion_IA_CalAmp_Wialon_Seguridad_Patrimonial_MEJORADA.pptx` x2 (460k)
- `Integracin_prctica_de_IA_para_seguridad_patrimonial_con_CalAmp_y_Wialon.pdf` x4 (120k)
- `WhatsApp Chat - TGL gps .zip` (590MB)
- `DIODE_IoT_Webinar_4_Febrero_Calamp_soluciones_control_flotas.pdf` (4MB)
- `CALAMP-20260918T040919Z-1-001.zip` (11MB)

**Pendiente Drive:** Si quieres que integre el ZIP de WhatsApp TGL gps (590MB) y el CALAMP-20260918 ZIP (11MB) con fotos, manuales y PEGs, dime y los descomprimo y agrego al MD.

---

## 14. PRÓXIMOS PASOS

- [ ] Empaquetar MOBILE.html como APK real con Buildozer / MIT App Inventor para compartir por WhatsApp sin Chrome
- [ ] Servicio Termux en segundo plano que escuche SMS y alerte Telegram cuando detecte 3E70
- [ ] Integración Wialon API para historial accum y graficar falla en tiempo
- [ ] Base de datos HEX de todas las CT para ML de fallas
- [ ] Integrar presentación IA CalAmp Wialon Seguridad Patrimonial al dashboard

---

*Generado por Meta AI - Para Nesthor CV - Torreón - Android Motorola + Termux + Termux:API*
*CalAmp LMU 27xx/4250 PEG 445 8.7b/8.6l REV12335-REL/REV10979-REL - Telcel INTERNET.ITELCEL.COM - LMD 94.130.84.182:20924*
*Falla clave: 0x3E70=15984 circuito abierto Dallas DS18B20 - Solución: revisar manguera corrugada chasis-caja + S171=65 + PEG ACTION 93*
