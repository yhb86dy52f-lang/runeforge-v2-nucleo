process.env.PORT = process.env.PORT || 3198;
// ==============================================================================
// RUNEFORGE RELAY - SERVIDOR LOCAL OFFLINE-FIRST Y PROXY DE IA
// ==============================================================================
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const PUBLIC_DIR = path.join(__dirname, 'public');

// Base de conocimiento incrustada de alta precisión (Sin fallos de vectores)
const CINER_KNOWLEDGE_BASE = `
DIRECTRICES TÉCNICAS Y METROLÓGICAS (PERFIL CINER):
- Sensores de Combustible: Escort TD-500 / TD-600.
- Algoritmo de Calibración: PCHIP (Spline Cúbico Monotónico) para Wialon.
- Cantidad de Puntos Óptima: Exactamente 100 puntos en la tabla ADC,Litros.
- Margen de Error Máximo Tolerado en Extremos: 0.08 Litros.
- Arquitectura de la PWA: IndexedDB primario para persistencia offline segura en iOS/Android, LocalStorage exclusivo para borradores.
`;

const server = http.createServer(async (req, res) => {
    // CORS Headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    // Endpoint de Inteligencia Artificial (Conexión directa a Ollama)
    if (req.url === '/api/ai/chat' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', async () => {
            try {
                const parsed = JSON.parse(body);
                const userMessage = parsed.message || '';

                // Construir el prompt maestro combinando la identidad, el conocimiento y la pregunta
                const fullPrompt = `
Eres CINER / Tinkerbell, Ingeniero Senior Copiloto en Telemetría GPS, IoT, Metrología y Wialon.
Trabajas como colega técnico del Ing. Néstor. Eres experto absoluto y nunca dices ser un asistente genérico.

${CINER_KNOWLEDGE_BASE}

Consulta del Ing. Néstor: ${userMessage}
Respuesta técnica directa:`;

                // Petición HTTP nativa a Ollama (Puerto 11434)
                const ollamaData = JSON.stringify({
                    model: 'deepseek-coder',
                    prompt: fullPrompt,
                    stream: false,
                    options: { temperature: 0.1 }
                });

                const ollamaReq = http.request({
                    hostname: 'localhost',
                    port: 11434,
                    path: '/api/generate',
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Content-Length': Buffer.byteLength(ollamaData)
                    }
                }, (ollamaRes) => {
                    let ollamaBody = '';
                    ollamaRes.on('data', chunk => { ollamaBody += chunk; });
                    ollamaRes.on('end', () => {
                        try {
                            const result = JSON.parse(ollamaBody);
                            res.writeHead(200, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify({
                                status: 'success',
                                response: result.response || 'Sin respuesta del modelo.'
                            }));
                        } catch (e) {
                            res.writeHead(500, { 'Content-Type': 'application/json' });
                            res.end(JSON.stringify({ error: 'Error parseando respuesta de Ollama.' }));
                        }
                    });
                });

                ollamaReq.on('error', (err) => {
                    res.writeHead(500, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: 'Ollama no está activo en el puerto 11434.' }));
                });

                ollamaReq.write(ollamaData);
                ollamaReq.end();

            } catch (err) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'JSON inválido en la petición.' }));
            }
        });
        return;
    }

    // Servidor de Archivos Estáticos (PWA Bitácora)
    let filePath = path.join(PUBLIC_DIR, req.url === '/' ? 'bitacora.html' : req.url);
    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('404 No encontrado');
        } else {
            let ext = path.extname(filePath);
            let contentType = 'text/html';
            if (ext === '.js') contentType = 'application/javascript';
            if (ext === '.css') contentType = 'text/css';
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(content);
        }
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`[RUNEFORGE-RELAY OPTIMIZADO] Sistema en línea en http://localhost:${PORT}`);
});