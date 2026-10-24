# Telemetría GPS - CalAmp CT - Bitácora Completa
## Trabajo con Nesthor CV - Torreón - 2026-10-20

> Archivo maestro generado de toda la conversación sobre cajas termo, fallas de sensores y decodificación SMS

---

### 1. RESUMEN EJECUTIVO

Se analizaron **6 unidades CT con falla/buen estado de sensores de temperatura de caja termo** conectadas a plataforma Wialon / tgarzaleal.
Falla detectada: `accum_2, accum_3, accum_4, accum_5 = 15984` constante = `0x3E70` sentinel de circuito abierto Dallas DS18B20.

Unidades:
- **CT199** - FALLA DOBLE TERMO (2x 3E70) - MID 4672144079 - 11.2V
- **CT227 BUENO** - FALLA SIMPLE RESIDUAL (1x 3E70 + 01C0) - MID 7000276162 - 12.4V - Aún operativo con 1 sonda
- **871 102 5254** - BUENO PERFECTO (0x 3E70, 0x FFFF) - MID 4672124239 - 12.5V - Patrón de referencia sano
- **CT256** - OK DESHABILITADO (FFFF) - MID 7000275353 - 14.0V - PEG con accums deshabilitados
- **CT194** - OK DESHABILITADO (FFFF) - MID 4672133919 - 13.5V - REV10979-REL

---

### 2. ESTRUCTURA DE DATOS DE PLATAFORMA (Wialon)

Ejemplo crudo:
```
rssi=-57, hdop=0.7, unit_status=0, event_index=21, event_code=50, accum_0=11369, accum_1=4070, accum_2=15984, accum_3=15984, accum_4=15984, accum_5=15984, report_type=2, seq_num=1, host=200.68.152.100:20924, iridium=0, I/O=6/0
```

- **rssi -55 a -90**: señal Telcel (DA. INTERNET.ITELCEL.COM)
- **hdop 0.6-1.0**: GPS 3D-RTIME / 3D-DIFF 16-20 sats
- **event_index=6 / event_code=10**: reporte periódico 10 min
- **event_index=3 / event_code=1**: ignición ON
- **event_index=0 / event_code=0**: ignición OFF
- **event_index=21 / event_code=50**: power-up / cambio de host LMD
- **I/O 6/0=110 OFF, 7/0=111 ON, 26/0=11010 con puerta**
- **host 200.68.152.x / 200.68.153.60**: LMD 94.130.84.182:20924
- **accum_0**: Voltaje unidad (ADCO) 11248-11430 mV = 11.2-11.4V
- **accum_1**: Voltaje GPS (ADC5) 4068-4070 mV = 4.06V
- **accum_2-5**: Temperatura - FALLA 15984 = 0x3E70

---

### 3. MENSAJES SMS PEG - COMANDOS

- `!r0` -> `APP:445 8.7b / 8.6l COM:-87 DA. INTERNET.ITELCEL.COM GPS:3D-RTIME 17 INP:0000000000000111 11.2V MID:4672144079 ESN` + `INB:94.130.84.182:20924 LMD APP2:REV12335-REL`
- `!r4` -> Dump PEG en HEX largo (60-63 bytes) `! E4672144079FFFFFF0100006AD7...`
- `!ra` / `!r3,70,0` -> `#ADCO: 11248 mV #ADC1: 0 mV #ADC2: 540 mV #ADC3: 38 degC #ADC4: 1202 mV #ADC5: 4068 mV #ADC6: 780 mV #ADC7: 4195 mV`
- `!rg` -> `-86 DA. 10.115.225.80 20510 INTERNET.ITELCEL.COM M: dm.calamp.com 20500 I: 94.130.84.182 20924`
- `!r3,70,0` -> reset
- `!RP,2306,0,APN` -> configurar APN por SMS
- `ATS171=65` -> habilitar bus 1-Wire
- `AT$APP PEG ACTION 93 0` -> mover temp sensor 0 a accumulator 0
- `AT$APP PEG ACTION 93 1` -> mover temp sensor 1 a accumulator 1

---

### 4. DECODIFICACIÓN HEX !r4 - HALLAZGOS

Todos los HEX tienen longitud impar (125) por un 0 perdido al inicio. Al limpiar:

**Patrón de cola (últimos 12 bytes = 6x uint16 BE):**
- `2C0E = 11278` = 11.27V CT199
- `2CA6 = 11430` = 11.43V CT199
- `2FF9 = 12281` = 12.28V ~ 12.4V CT227
- `30B0 = 12464` = 12.46V ~ 12.5V 871
- `34D8 = 13528` = 13.5V CT194
- `36DC = 14044` = 14.04V CT256
- `0FE4 = 4068` = 4.06V GPS
- `0FE6 = 4070` = 4.07V GPS
- `03E70 = 15984` = FALLA circuito abierto
- `FFFF = 65535` = acumulador deshabilitado en PEG
- `01C0 = 448` = 44.8°C lectura buena CT227
- `0123 = 291` = 29.1°C lectura buena 871

**Hex completos integrados:**

```
CT199_FALLA_1: E4672144079FFFFFF0100006AD7AD6F6AD7AD6F0F39DD9EC24A588B00000002005C11000014FFAB8F070700FFFF0400002C0E00000FE400003E7000003E70
CT199_FALLA_2: E4672144079FFFFFF0100006AD7B0E06AD7B0E00F39DBB9C24A548500000002001912000014FFA88F080600FFFF0400002CA600000FE400003E7000003E70
CT227_BUENO: E7000276162FFFFFF0100006AD7B38D6AD7B38D0F39E11FC24A4A2E00000000008213020014FFA58F060600FFFF0400002FF900000FE60000001C000003E70
871_BUENO: E4672124239FFFFFF0100006AD7B3A56AD7B3A50BF446EEC4CF904400000000004B14000014FFAA8F060600FFFF04000030B000000FF60000010300000123
CT256_FFFF: E7000275353FFFFFF0100006AD7B3A46AD7B3A40BF34AFFC4D6E8BC00000000004B15020014FFA08F062500FFFF04000036DC00000FE0FFFFFFECFFFFFFF
CT194_FFFF: E4672133919FFFFFF0100006AD7B38A6AD7B3890F658243C441928A00000002013913020014FFA08F082500FFFF04000034D800000FF2FFFFFF6AFFFFFF3F
```

**Lógica de diagnóstico para app:**
```python
c_3E70 = u16.count(0x3E70)
c_FFFF = u16.count(0xFFFF)
if c_3E70 >=2: FALLA_DOBLE_TERMO (ROJO)
elif c_3E70==1: FALLA_SIMPLE_RESIDUAL (AMARILLO) - CT227
elif c_FFFF>=2 and c_3E70==0: OK_DESHABILITADO (AZUL)
else: BUENO_PERFECTO (VERDE) - 871
```

---

### 5. SENSORES TEMPERATURA CALAMP 4 HILOS

**Colores:** Rojo, Azul, Negro, Blanco - 2 sondas Dallas DS18B20 en una manguera

Según manual CalAmp 26xx/27xx y LMU-4250:
- **BLANCO = DATA** (sonda 1) - Pin 17 White/Blue 1BB-D
- **AZUL = ENABLE / DATA2** (sonda 2) - También a Pin 17 White/Blue
- **NEGRO = GROUND** (común) - Pin 1, 16, 22 Black GND / 1BB-GND - 2 negros van juntos
- **ROJO = OUT / VCC** - Pin 9 Orange VDD 20-25mA max - Alimentación

**Conexión correcta:**
- Negro+Negro -> Black GND CalAmp
- Blanco -> White/Blue 1BB-D
- Azul -> White/Blue 1BB-D (mismo bus)
- Rojo -> Orange VDD (o con resistencia 4.7k a White/Blue para modo parásito)

**Si solo usas negro negro blanco azul (sin rojo):** quedas en modo parásito, funciona pero inestable, por eso a veces 15984.

**S171=65** obligatorio para habilitar bus 1-Wire.

### Prueba con multímetro

**Desconectado, Ω 20k:**
- Negro-Negro: 0Ω (mismo)
- Blanco-Negro: ~10k-15kΩ a 25°C si es NTC, o OL si es Dallas bueno. OL = cable trozado (falla 90%)
- Azul-Negro: igual
- Blanco-Azul: OL, si 0Ω corto entre datas
- Rojo-Negro: >50kΩ o OL, si 0Ω sensor quemado

**Conectado, VDC 20V:**
- Rojo-Negro: 3.3-5V fijos
- Blanco-Negro: 3.5-4.8V fluctuando (comunicación). 0V fijo = bus a tierra, 5V fijo sin brinco = S171 mal
- Azul-Negro: igual fluctuante

**Si ves fluctuación pero Wialon sigue 15984:** es PEG, no cable. Revisar `PEG ACTION 93`.

---

### 6. HERRAMIENTAS DESARROLLADAS

#### A) CT Thermo Lab Pro v3 Dashboard (Web)
Archivo: `ct_thermo_lab_pro_agentic_artifact_2_216678b4de69.html`
- Gauges circulares voltaje
- Camión SVG con sondas iluminadas verde/rojo/gris
- Gráficas barras comparativa 6 casos
- Tabla comparativa
- Timeline accum tail
- JSON normalizado

#### B) CT Thermo Lab MOBILE APK (PWA)
Archivo: `CT_Thermo_Lab_Pro_MOBILE.html`
- Instalable en Motorola: Chrome -> ⋮ -> Agregar a pantalla principal
- Botón 📋 Pegar del portapapeles
- Optimizado para campo, offline

#### C) Decoders Python para Termux
- `calamp_decoder.py` - v1 básico
- `calamp_decoder_v3.py` - v3 con 6 casos, conteo 3E70/FFFF
```bash
python calamp_decoder_v3.py "E7000276162FFFFFF..."
termux-sms-list -l 30 | grep -oE "[0-9A-F]{120,}" | tail -1 | xargs python calamp_decoder_v3.py
```

#### D) Scripts Termux
- `termux_ct199.sh` - v1
- `termux_ct199_v2.sh` - v3 auto lector
```bash
chmod +x termux_ct199_v2.sh
./termux_ct199_v2.sh
termux-sms-send -n NUMERO "!r4"
```

---

### 7. COMANDOS PEG Y REGISTROS

- `AT$APP PARAM 772,0,2` -> número de acumuladores a transmitir
- `AT$APP PEG ACTION 93 0` -> temp0 a accum0
- `AT$APP PEG ACTION 93 1` -> temp1 a accum1
- `AT$APP PARAM 1024,35,255,1` -> reset config
- `ATS171=65` -> habilitar 1-Wire
- `S158 bit 1-7` -> bias inputs
- `S181 bit 4 (16)` -> HTS sensor

**Plataforma Wialon sensores:**
- Ignición: `in1` sensor ignición motor Ence... 
- Voltaje Unidad: `accum_0` V
- Voltaje GPS: `accum_1` V
- Motor: `in2`
- Temperatura: `accum_2` °C
- Temperatura F: personalizado °F `const32` + `const1.8` -> `(C*1.8)+32`
- Validador Temp: `const1.8`

---

### 8. DIAGNÓSTICO FINAL CT199

- **Causa raíz:** Cableado de manguera termo trozado en la articulación chasis-caja. No es sonda.
- **Evidencia:** `accum_2-5 = 15984` constante en 50 reportes, `hdop 0.6-1.0` y `rssi -55 a -88` OK, voltajes OK, solo falla en temp.
- **Solución:** Revisar manguera corrugada entre cabina y caja, medir continuidad Blanco-Negro y Azul-Negro. Reemplazar si OL. Verificar pull-up 4.7k y S171=65. Si sigue, cambiar sonda doble Dallas.

---

### 9. PRÓXIMOS PASOS PROPUESTOS

- [ ] Empaquetar MOBILE.html como APK real con Buildozer para compartir por WhatsApp
- [ ] Integrar `termux-sms-list` a servicio en segundo plano que alerte Telegram cuando detecte 3E70
- [ ] Conectar a Wialon API para historial de accum y graficar falla en tiempo
- [ ] Crear base de datos de HEX de todas las CT para machine learning de fallas

---

### 10. ARCHIVOS ENTREGADOS

- `ct_thermo_lab_pro_agentic_artifact_2_216678b4de69.html` - Dashboard Pro v3
- `CT_Thermo_Lab_Pro_MOBILE.html` - APK PWA Móvil
- `calamp_decoder.py` - Decoder v1
- `calamp_decoder_v3.py` - Decoder v3 con 6 casos
- `termux_ct199.sh` - Termux v1
- `termux_ct199_v2.sh` - Termux v3
- Este MD `telemetria_gps_sensores_equipos.md`

---

*Generado por Meta AI para Nesthor CV - Torreón - Trabajo en Android Motorola con Termux + Termux:API*
*Equipos CalAmp LMU 27xx/4250 - PEG 445 8.7b / 8.6l - REV12335-REL / REV10979-REL*
