import streamlit as st
import pandas as pd
import re
import requests
import os
from datetime import datetime

st.set_page_config(page_title="Runeforge TGL - Decoder", page_icon="📡", layout="wide")
st.title("📡 Runeforge - Decodificador de Telemetría y Mantenimiento Predictivo")
st.caption("Sistema de Soberanía Digital Local - Transportes Garza Leal")

def decodificar_tramas(texto):
    lineas = texto.split('\n')
    registros = []
    
    patron_params = re.compile(r'rssi=(-?\d+), hdop=([\d.]+), unit_status=(\d+), event_code=(\d+), accum_0=(\d+), accum_1=(\d+), accum_2=(\d+), accum_3=(\d+), accum_4=(\d+), accum_5=(\d+), accum_6=(\d+), accum_7=(\d+), esc_temp_0=(\d+), esc_lev_0=(\d+), esc_temp_1=(\d+), esc_lev_1=(\d+)')
    
    patron_linea = re.compile(r'^\|\s*(\d+)\s*\|\s*([\d-]+ [\d:]+)\s*\|\s*(\d+)\s*\|\s*([\d.,-]+)\s*,\s*([\d.,-]+)\s*\(.*?\)\s*\|\s*([\d.]+)\s*\|\s*(.*?)\s*\|', re.IGNORECASE)

    for linea in lineas:
        match_params = patron_params.search(linea)
        match_linea = patron_linea.search(linea)

        if match_params:
            tiempo = match_linea.group(2) if match_linea else "N/A"
            velocidad = match_linea.group(3) if match_linea else 0
            lat = match_linea.group(4) if match_linea else "N/A"
            lon = match_linea.group(5) if match_linea else "N/A"

            voltaje_unidad = int(match_params.group(5)) / 1000.0
            voltaje_gps = int(match_params.group(6)) / 1000.0
            odometro = int(match_params.group(10)) / 1000.0
            temp1 = int(match_params.group(15)) - 273.15
            temp2 = int(match_params.group(13)) - 273.15
            comb1 = int(match_params.group(16)) / 10.0
            comb2 = int(match_params.group(14)) / 10.0

            registros.append({
                'Hora': tiempo, 'Vel (km/h)': velocidad, 'Lat': lat, 'Lon': lon,
                'Volt. Unidad (V)': round(voltaje_unidad, 2), 'Volt. GPS (V)': round(voltaje_gps, 2),
                'Odómetro (km)': round(odometro, 2), 'Temp T1 (°C)': round(temp1, 1),
                'Temp T2 (°C)': round(temp2, 1), 'Comb. T1 (L)': round(comb1, 1), 'Comb. T2 (L)': round(comb2, 1)
            })
    
    return pd.DataFrame(registros)

tab1, tab2, tab3 = st.tabs(["📥 1. Pegar Datos", "🤖 2. Análisis IA", "💾 3. Guardar en Obsidian"])

with tab1:
    st.subheader("Pega los datos crudos (exportados de la plataforma)")
    raw_input = st.text_area("Área de texto", height=400, placeholder="Pega aquí el contenido de 'raw data.md' o 'sensor value.md'...")
    
    if st.button("🔓 DECODIFICAR AHORA"):
        if raw_input:
            df = decodificar_tramas(raw_input)
            if not df.empty:
                st.session_state['datos_decodificados'] = df
                st.success(f"✅ Éxito: {len(df)} mensajes decodificados correctamente.")
                st.dataframe(df, use_container_width=True)
                
                csv = df.to_csv(index=False).encode('utf-8')
                st.download_button("⬇️ Descargar CSV Decodificado", csv, "telemetria_tgl.csv", "text/csv")
            else:
                st.error("❌ No se encontraron tramas válidas. Revisa el formato pegado.")
        else:
            st.warning("⚠️ Pega datos en el área de texto primero.")

with tab2:
    st.subheader("Análisis Predictivo con IA Local (Ollama)")
    if 'datos_decodificados' in st.session_state:
        df = st.session_state['datos_decodificados']
        ultimo = df.iloc[-1]
        
        st.write("Último registro decodificado:")
        st.write(ultimo)

        if st.button("🚀 Generar Recomendación con Ollama"):
            prompt = f"""
Eres un Ingeniero de Mantenimiento Predictivo. Basado en estos datos del último minuto:
- Voltaje Unidad: {ultimo['Volt. Unidad (V)']} V
- Voltaje GPS: {ultimo['Volt. GPS (V)']} V
- Odómetro: {ultimo['Odómetro (km)']} km
- Temperatura T1: {ultimo['Temp T1 (°C)']} °C
- Temperatura T2: {ultimo['Temp T2 (°C)']} °C
¿Cuál es el riesgo de falla y qué mantenimiento preventivo sugieres? Responde en español técnico.
"""
            try:
                response = requests.post('http://localhost:11434/api/generate', 
                                         json={"model": "qwen2.5:1.5b", "prompt": prompt, "stream": False})
                st.success(f"**Recomendación IA:** {response.json()['response']}")
            except Exception:
                st.error("No se pudo conectar con Ollama. Asegúrate de tenerlo corriendo en localhost:11434.")
    else:
        st.info("Primero decodifica los datos en la pestaña 1.")

with tab3:
    st.subheader("Guardar Reporte en Obsidian (Runeforge)")
    if 'datos_decodificados' in st.session_state:
        df = st.session_state['datos_decodificados']
        
        ruta_obsidian = st.text_input("Ruta de Obsidian", r"C:\Users\TU_USUARIO\Documents\Obsidian\Runeforge\Fleet_Intel")
        
        if st.button("💾 Generar Nota Markdown"):
            os.makedirs(ruta_obsidian, exist_ok=True)
            nombre_nota = f"Telemetria_TGL_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
            
            markdown = df.to_markdown(index=False)
            nota = f"""---
title: "Análisis de Telemetría TGL"
date: {datetime.now().strftime('%Y-%m-%d')}
tags: [runeforge, telemetry, mantenimiento]
---

# 📡 Reporte Automático de Telemetría

## Datos Decodificados (Última Lectura)
| Métrica | Valor |
|---|---|
| Voltaje Unidad | {df.iloc[-1]['Volt. Unidad (V)']} V |
| Voltaje GPS | {df.iloc[-1]['Volt. GPS (V)']} V |
| Odómetro | {df.iloc[-1]['Odómetro (km)']} km |
| Temp T1 | {df.iloc[-1]['Temp T1 (°C)']} °C |
| Temp T2 | {df.iloc[-1]['Temp T2 (°C)']} °C |
| Combustible T1 | {df.iloc[-1]['Comb. T1 (L)']} L |

## Historial Completo
{markdown}
"""
            with open(os.path.join(ruta_obsidian, nombre_nota), "w", encoding="utf-8") as f:
                f.write(nota)
            st.success(f"✅ Nota guardada en: {nombre_nota}")
    else:
        st.info("Primero decodifica los datos en la pestaña 1.")
