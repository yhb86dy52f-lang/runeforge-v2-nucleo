const { runSystemSkill } = require('./skills/system');
const { runTelemetriaSkill } = require('./skills/telemetria');
const { runGeneralSkill } = require('./skills/general');

function detectRoute(message, moduleHint) {
  const text = message.toLowerCase();

  if (moduleHint === 'system') return 'system';
  if (moduleHint === 'telemetria') return 'telemetria';
  if (moduleHint === 'general') return 'general';

  if (
    text.includes('health') ||
    text.includes('status') ||
    text.includes('estado del sistema') ||
    text.includes('sistema') ||
    text.includes('backend')
  ) {
    return 'system';
  }

  if (
    text.includes('gps') ||
    text.includes('apn') ||
    text.includes('inbound') ||
    text.includes('telemetria') ||
    text.includes('calamp')
  ) {
    return 'telemetria';
  }

  return 'general';
}

async function resolveSkill(ctx) {
  const route = detectRoute(ctx.message, ctx.moduleHint);

  switch (route) {
    case 'system':
      return runSystemSkill(ctx);
    case 'telemetria':
      return runTelemetriaSkill(ctx);
    default:
      return runGeneralSkill(ctx);
  }
}

module.exports = { resolveSkill };