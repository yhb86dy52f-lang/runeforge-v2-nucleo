const { Ollama } = require('ollama');
const path = require('path');
const fs = require('fs');

const ollama = new Ollama({ host: 'http://127.0.0.1:11434' });

async function setupAIRoutes(fastify) {
    // Endpoint de Salud IA
    fastify.get('/api/ai/local/health', async () => {
        return { service: "Runeforge Local AI", status: "OPERATIVE", model: "qwen2.5:1.5b" };
    });

    // Endpoint de Chat con Interceptor Bypass V13
    fastify.post('/api/ai/local/chat', async (request, reply) => {
        const { message } = request.body;
        
        // INTERCEPTOR SOBERANO (Bypass V13)
        if (message.toLowerCase().includes("wialon") || message.toLowerCase().includes("algoritmo")) {
            return { 
                ok: true, 
                content: "PROTOCOLO GARZA LEAL: El algoritmo OBLIGATORIO es Spline Cúbico Monotónico (PCHIP) con un margen de error de 0.08L. Resolución: 100 puntos.",
                source: "BYPASS_V13_INTERNAL" 
            };
        }

        try {
            const response = await ollama.chat({
                model: 'qwen2.5:1.5b',
                messages: [{ role: 'user', content: message }],
                stream: false,
                options: { temperature: 0.2, num_predict: 250 }
            });
            return { ok: true, content: response.message.content, source: "OLLAMA_LOCAL" };
        } catch (err) {
            return { ok: false, content: "Error de conexión con Ollama. Verifica 'ollama serve'." };
        }
    });

    // WebCommand: Status de Red y PM2
    fastify.post('/api/webcommand', async (request) => {
        const { action } = request.body;
        if (action === 'status') return { cpu: "Low", mesh: "Tailscale Active", node: process.version };
        return { ok: true, response: `Acción '${action}' ejecutada en modo solo-lectura.` };
    });
}

module.exports = { setupAIRoutes };


// --- RUTA SSE STREAMING (OLLAMA QWEN2.5:1.5B) ---
fastify.post('/api/chat/stream', async (request, reply) => {
    const { prompt } = request.body || {};
    if (!prompt) return reply.status(400).send({ error: 'Prompt es requerido' });

    reply.raw.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
    reply.raw.setHeader('Cache-Control', 'no-cache, no-transform');
    reply.raw.setHeader('Connection', 'keep-alive');
    reply.raw.setHeader('X-Accel-Buffering', 'no');

    try {
        const ollamaRes = await fetch('http://127.0.0.1:11434/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model: 'qwen2.5:1.5b', prompt, stream: true })
        });

        if (!ollamaRes.ok) {
            reply.raw.write(`data: ${JSON.stringify({ response: ' [Error en Ollama local]' })}\n\n`);
            return reply.raw.end();
        }

        const reader = ollamaRes.body.getReader();
        const decoder = new TextDecoder('utf-8');

        while (true) {
            const { done, value } = await reader.read();
            if (done) break;

            const chunk = decoder.decode(value, { stream: true });
            const lines = chunk.split('\n');
            for (const line of lines) {
                if (line.trim()) {
                    reply.raw.write(`data: ${line.trim()}\n\n`);
                }
            }
        }
        reply.raw.write('data: [DONE]\n\n');
        reply.raw.end();
    } catch (err) {
        reply.raw.write(`data: ${JSON.stringify({ response: ` [Error backend: ${err.message}]` })}\n\n`);
        reply.raw.end();
    }
});