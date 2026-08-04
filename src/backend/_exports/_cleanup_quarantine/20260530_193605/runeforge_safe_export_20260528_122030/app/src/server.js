const path = require('path');
const app = require('./app');
const env = require('./config/env');
const logger = require('./shared/logger');

app.listen(env.port, env.host, () => {
  logger.info('runeforge_started', {
    service: env.appName,
    env: env.nodeEnv,
    port: env.port,
    host: env.host
  });
});


app.post('/api/chat', (req, res) => {
  const input = String(req.body?.input ?? req.body?.message ?? '').trim();

  const text = input
    ? 'Runeforge recibió: ' + input
    : 'Runeforge listo.';

  return res.json({
    ok: true,
    input,
    reply: {
      text,
      blocks: [
        { type: 'text', text }
      ]
    },
    meta: {
      skill: 'general',
      mode: 'mvp'
    }
  });
});



// [RUNEFORGE FIX] Servidor de archivos estáticos para PWA
import path from 'path';
import fastifyStatic from '@fastify/static';

fastify.register(fastifyStatic, {
    root: 'C:/RUNEFORGE_V2_CORE/public',
    prefix: '/',
});

fastify.setNotFoundHandler((request, reply) => {
    if (request.raw.url && !request.raw.url.startsWith('/api')) {
        return reply.sendFile('index.html');
    }
    reply.status(404).send({ error: 'Not Found', message: 'Ruta no encontrada', statusCode: 404 });
});
