const { routeAndSave } = require('../skills/intent_router');

async function vaultRoutes(fastify, options) {
    fastify.post('/api/v1/vault/smart-note', async (request, reply) => {
        const { content } = request.body || {};
        if (!content) {
            return reply.code(400).send({ error: 'El campo content es obligatorio.' });
        }
        const result = await routeAndSave(content);
        return reply.send(result);
    });
}

module.exports = vaultRoutes;
