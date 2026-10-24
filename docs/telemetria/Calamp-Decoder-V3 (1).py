#!/usr/bin/env python3
# CT Thermo Lab Pro - Decoder v3 para Termux
# Uso: python calamp_decoder_v3.py "E7000276162FFFFFF..."
import re, sys, json

def clean_hex(s):
    c = re.sub(r'[^0-9A-Fa-f]', '', s).upper()
    if len(c)%2==1:
        c='0'+c
    return c

def decode(hex_str):
    clean = clean_hex(hex_str)
    b = [int(clean[i:i+2],16) for i in range(0,len(clean),2)]
    u16 = [(b[i]<<8)|b[i+1] for i in range(0,len(b)-1,2)]
    c_3E70 = u16.count(0x3E70)
    c_FFFF = u16.count(0xFFFF)
    volt_u_candidates = [v for v in u16 if 10000 <= v <= 16000]
    volt_g_candidates = [v for v in u16 if 3500 <= v <= 5000]
    volt_u = volt_u_candidates[-1] if volt_u_candidates else None
    volt_g = volt_g_candidates[-1] if volt_g_candidates else None
    temp_buena = None
    for v in u16[-5:]:
        if 100 <= v <= 1000 and v not in (0x3E70,0xFFFF):
            temp_buena=v
    if c_3E70>=2:
        estado="FALLA_DOBLE_TERMO"; color="ROJO"
        reco="2x 15984 = ambas sondas Dallas en circuito abierto. Revisar arnes 1-Wire y pull-up 4.7k en ADC2/ADC3."
    elif c_3E70==1:
        estado="FALLA_SIMPLE_RESIDUAL"; color="AMARILLO"
        reco=f"1x 15984 residual, otra sonda en {temp_buena} ({temp_buena/10 if temp_buena else '?'}C) sigue OK. Como CT227 BUENO."
    elif c_FFFF>=2 and c_3E70==0:
        estado="OK_DESHABILITADO"; color="AZUL"
        reco="FFFF = acumuladores deshabilitados en PEG REV10979/12335, no es falla."
    elif c_3E70==0 and c_FFFF==0:
        estado="BUENO_PERFECTO"; color="VERDE"
        reco="Sin 3E70 ni FFFF, termo OK. Patron referencia 8711025254."
    else:
        estado="DESCONOCIDO"; color="GRIS"; reco="Patron no clasificado"
    return {
        "mid": "7000276162" if "7000276162" in clean else "4672144079" if "4672144079" in clean else "auto",
        "volt_unidad_v": round(volt_u/1000,2) if volt_u else None,
        "volt_gps_v": round(volt_g/1000,3) if volt_g else None,
        "conteo_3E70": c_3E70,
        "conteo_FFFF": c_FFFF,
        "estado": estado,
        "color": color,
        "recomendacion": reco,
        "u16_tail": u16[-10:],
    }

if __name__ == "__main__":
    data = " ".join(sys.argv[1:]) if len(sys.argv)>1 else sys.stdin.read()
    if not data.strip():
        print("Pega HEX !r4")
        sys.exit(0)
    matches = re.findall(r'[0-9A-Fa-f]{100,}', data)
    target = matches[-1] if matches else data
    res = decode(target)
    print(json.dumps(res, indent=2, ensure_ascii=False))
    print(f"\n{res['color']} - {res['estado']}\n{res['recomendacion']}")
