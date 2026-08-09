const fastify = require('fastify')({ logger: true });
const path = require('path');

fastify.register(require('@fastify/static'), {
    root: path.join(__dirname, 'public'),
    prefix: '/'
});

const start = async () => {
    try {
        await fastify.listen({ port: 3100, host: '0.0.0.0' });
        console.log('Server listening on http://0.0.0.0:3100');
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};
start();

// --- RUTA SSE STREAMING (OLLAMA QWEN2.5:1.5B) ---
fastify.post('/api/chat/stream', async (request, reply) => {
    const { prompt } = request.body || {};
    if (!prompt) return reply.status(400).send({ error: 'Prompt es requerido' });

    reply.raw.setHeader('Content-Type', 'text/event-stream');
    reply.raw.setHeader('Cache-Control', 'no-cache, no-transform');
    reply.raw.setHeader('Connection', 'keep-alive');
    reply.raw.setHeader('X-Accel-Buffering', 'no');

    try {
        const ollamaRes = await fetch('http://0.0.0.0:11434/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model: 'qwen2.5:1.5b', prompt, stream: true })
        });

        if (!ollamaRes.ok) {
            reply.raw.write(`data: ${JSON.stringify({ response: ' [Error conectando a Ollama local]' })}\n\n`);
            return reply.raw.end();
        }

        for await (const chunk of ollamaRes.body) {
            const textChunk = new TextDecoder().decode(chunk);
            const lines = textChunk.split('\n');
            for (const line of lines) {
                if (line.trim()) {
                    reply.raw.write(`data: ${line.trim()}\n\n`);
                }
            }
        }
        reply.raw.write('data: [DONE]\n\n');
        reply.raw.end();
    } catch (err) {
        reply.raw.write(`data: ${JSON.stringify({ response: ' [Excepcion en backend Fastify]' })}\n\n`);
        reply.raw.end();
    }
});
