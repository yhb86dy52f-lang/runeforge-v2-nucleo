const fastify = require('fastify')({ logger: true });
fastify.register(require('@fastify/cors'), { origin: true });
fastify.get('/', async () => ({ ok:true, service:'relay', port:3198, status:'online', ts:new Date().toISOString() }));
fastify.listen({ port:3198, host:'0.0.0.0' }, (err, addr) => { if(err){ console.error(err); process.exit(1);} console.log('RELAY OK '+addr); });
