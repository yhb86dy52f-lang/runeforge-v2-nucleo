const env = require('../../config/env');

function getAiStatus() {
  return {
    provider: env.ai.provider || 'not-configured',
    model: env.ai.model || 'not-configured',
    configured: Boolean(env.ai.apiKey)
  };
}

module.exports = { getAiStatus };
