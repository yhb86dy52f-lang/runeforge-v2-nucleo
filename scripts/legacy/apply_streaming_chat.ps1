$ErrorActionPreference = "Stop"
$ServerJs = "C:\RUNEFORGE_V2_CORE\server.js"

$SSERouteCode = @'
// --- RUTA SSE STREAMING (OLLAMA QWEN2.5:1.5B) ---
fastify.post('/api/chat/stream', async (request, reply) => {
    const { prompt } = request.body || {};
    if (!prompt) return reply.status(400).send({ error: 'Prompt es requerido' });

    reply.raw.setHeader('Content-Type', 'text/event-stream');
    reply.raw.setHeader('Cache-Control', 'no-cache');
    reply.raw.setHeader('Connection', 'keep-alive');

    try {
        const ollamaRes = await fetch('http://127.0.0.1:11434/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ model: 'qwen2.5:1.5b', prompt, stream: true })
        });

        for await (const chunk of ollamaRes.body) {
            const textChunk = new TextDecoder().decode(chunk);
            const lines = textChunk.split('\n');
            for (const line of lines) {
                if (line.trim()) {
                    reply.raw.write(`data: ${line}\n\n`);
                }
            }
        }
        reply.raw.write('data: [DONE]\n\n');
        reply.raw.end();
    } catch (err) {
        reply.raw.write(`data: ${JSON.stringify({ response: ' [Error en Ollama]' })}\n\n`);
        reply.raw.end();
    }
});
'@

$content = Get-Content $ServerJs -Raw -Encoding UTF8
if ($content -notmatch '/api/chat/stream') {
    $content += "`n" + $SSERouteCode
    Set-Content -Path $ServerJs -Value $content -Encoding UTF8
    Write-Host "[OK] Ruta SSE inyectada en server.js" -ForegroundColor Green
} else {
    Write-Host "[INFO] La ruta SSE ya existe en server.js" -ForegroundColor Yellow
}

if (Get-Command pm2 -ErrorAction SilentlyContinue) {
    pm2 restart runeforge-backend
    Write-Host "[OK] Proceso PM2 runeforge-backend reiniciado." -ForegroundColor Green
} else {
    Write-Host "[WARN] PM2 no detectado en PATH global." -ForegroundColor Yellow
}