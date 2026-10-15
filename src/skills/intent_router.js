const axios = require('axios');
const path = require('path');
const fs = require('fs');

const VAULT_PATH = 'C:\\RUNEFORGE_V2_CORE\\knowledge\\vault';
const OLLAMA_URL = 'http://localhost:11434/api/generate';

const SYSTEM_PROMPT = `Eres el clasificador de intenciones de RUNEFORGE.
Analiza el texto del usuario y clasifícalo estrictamente en una de estas 4 categorías:
- "01_Diario": Rutinas, ejercicio, check-ins, estado de ánimo o bitácora personal.
- "02_Finanzas": Compras, gastos, precios, pagos, facturas o presupuestos.
- "03_Proyectos": Código, esquemas eléctricos, puertos serie/COM, telemetría (CalAmp, LMU), hardware, lavadoras, CCTV, scripts o guías técnicas.
- "04_Memoria": Reglas personales, metas, aprendizajes clave o contexto persistente a largo plazo.

Reglas:
1. Si el texto menciona marcas, componentes electrónicos, protocolos o configuración de hardware, SIEMPRE clasifica como "03_Proyectos".
2. Responde ÚNICAMENTE en JSON con el formato: {"category": "<categoria>", "cleanText": "<texto>"}`;

async function routeAndSave(userInput) {
    try {
        const response = await axios.post(OLLAMA_URL, {
            model: 'qwen2.5:1.5b',
            prompt: `${SYSTEM_PROMPT}\n\nTexto a clasificar: "${userInput}"`,
            stream: false,
            format: 'json'
        });

        const parsed = typeof response.data.response === 'string' 
            ? JSON.parse(response.data.response) 
            : response.data.response;

        const category = parsed.category || '01_Diario';
        const cleanText = parsed.cleanText || userInput;

        const dateStr = new Date().toISOString().split('T')[0];
        const targetDir = path.join(VAULT_PATH, category);
        
        if (!fs.existsSync(targetDir)) {
            fs.mkdirSync(targetDir, { recursive: true });
        }

        const filePath = path.join(targetDir, `${dateStr}.md`);
        const timeStr = new Date().toLocaleTimeString();
        const entry = `\n\n### [${timeStr}]\n${cleanText}`;

        if (!fs.existsSync(filePath)) {
            fs.writeFileSync(filePath, `# Registro - ${dateStr}\n` + entry, 'utf8');
        } else {
            fs.appendFileSync(filePath, entry, 'utf8');
        }

        return { success: true, category, fallback: false, path: filePath };
    } catch (err) {
        const dateStr = new Date().toISOString().split('T')[0];
        const fallbackPath = path.join(VAULT_PATH, '01_Diario', `${dateStr}.md`);
        const timeStr = new Date().toLocaleTimeString();
        fs.appendFileSync(fallbackPath, `\n\n### [${timeStr}]\n${userInput}`, 'utf8');
        return { success: true, category: '01_Diario', fallback: true, error: err.message, path: fallbackPath };
    }
}

module.exports = { routeAndSave };
