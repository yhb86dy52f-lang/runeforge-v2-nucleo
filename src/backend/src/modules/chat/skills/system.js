const os = require('os');
const env = require('../../../config/env');

async function runSystemSkill(ctx) {
  return {
    route: 'system',
    reply: {
      text: 'Estado básico del sistema obtenido.',
      blocks: [
        {
          type: 'header',
          text: 'Estado del sistema'
        },
        {
          type: 'kv',
          items: [
            { key: 'service', value: env.appName },
            { key: 'env', value: env.nodeEnv },
            { key: 'uptimeSec', value: String(Math.round(process.uptime())) },
            { key: 'node', value: process.version },
            { key: 'platform', value: process.platform },
            { key: 'hostname', value: os.hostname() }
          ]
        },
        {
          type: 'text',
          text: `Consulta recibida: ${ctx.message}`
        }
      ],
      allowedActions: []
    }
  };
}

module.exports = { runSystemSkill };
