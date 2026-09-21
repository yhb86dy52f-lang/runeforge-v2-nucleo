const fastify = require('fastify')({ logger: true });
fastify.register(require('@fastify/cors'), { origin: true });
fastify.get('/healthz', async () => ({ status: 'ok', soberania: '100%', port: 3100, ts: new Date().toISOString() }));
fastify.get('/health', async () => ({ ok: true }));
fastify.listen({ port: 3100, host: '0.0.0.0' }, (err, addr) => { if(err){ console.error(err); process.exit(1);} console.log('BACKEND OK ' + addr); });
