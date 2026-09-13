# Runeforge - Sistema de Decodificación y Mantenimiento Predictivo TGL

## Objetivo
Crear una capa de inteligencia externa que lea los datos de la plataforma de Transportes Garza Leal sin modificarla, los convierta en información legible y genere órdenes de mantenimiento preventivo con IA local.

## Arquitectura
1. **Extracción:** El usuario utiliza el botón "Export to file" de la plataforma (acceso analista).
2. **Decodificación:** Esta aplicación web local (Python + Streamlit) interpreta las tramas crudas (accum_0, esc_lev, etc.) y las convierte a Voltios, Kilómetros y Litros.
3. **Análisis:** Los datos decodificados se envían a Ollama (qwen2.5:1.5b) para generar alertas predictivas.
4. **Documentación:** Los resultados se guardan automáticamente en Obsidian con formato Dataview para su consulta histórica.

## Ventajas
- **Cero impacto en la plataforma principal.**
- **Soberanía total:** Los datos nunca salen de la PC local.
- **Hardware validado:** Interpretación de calibraciones de sensores (Voltaje, Temperatura, Combustible).
- **Auditable:** Todo queda documentado en Markdown para auditorías de mantenimiento.

## Uso
1. Instalar Python 3.10+
2. pip install -r requirements.txt
3. streamlit run app_runeforge.py
4. Pegar el contenido crudo en la pestaña 1 y presionar Decodificar.
