import Fastify from 'fastify';
import cors from 'cors';
import { swarmApp } from './index.js';

const fastify = Fastify({ logger: false });

fastify.addHook('onRequest', (req, res, done) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
        res.send();
    } else {
        done();
    }
});

fastify.get('/api/swarm/health', async () => {
    return { ok: true, service: 'Runeforge Swarm', status: 'ONLINE', port: 3105 };
});

fastify.post('/api/swarm/execute', async (request, reply) => {
    const { task } = request.body;
    if (!task) return reply.code(400).send({ error: 'El parámetro task es obligatorio.' });
    
    try {
        const start = Date.now();
        const result = await swarmApp.invoke({ task });
        const elapsed = Date.now() - start;
        
        return { 
            ok: true, 
            result: result.code, 
            trace: result.messages,
            meta: { elapsed_ms: elapsed }
        };
    } catch (error) {
        return reply.code(500).send({ error: error.message });
    }
});

fastify.listen({ port: 3105, host: '0.0.0.0' }, (err, address) => {
    if (err) {
        console.error(err);
        process.exit(1);
    }
    console.log(`⚡ [SWARM MICROSERVICE] Operativo en ${address}`);
});
