const env = require('../../../config/env');
const { executeCommand } = require('../../../core/command-registry');

function extractRequestedCommand(message) {
  const text = message.toLowerCase();

  if (text.includes('leer apn') || text === 'apn') return 'leer_apn';
  if (text.includes('inbound ip')) return 'leer_inbound_ip';
  if (text.includes('inbound port')) return 'leer_inbound_port';
  if (text.includes('gps status') || text.includes('status gps') || text.includes('estado gps')) return 'gps_status';
  if (text === 'status') return 'status';

  return null;
}

async function runTelemetriaSkill(ctx) {
  const requestedCommand = extractRequestedCommand(ctx.message);
  const allowedCommands = Array.isArray(env.allowedCommands) ? env.allowedCommands : [];

  let execution = null;

  if (requestedCommand && allowedCommands.includes(requestedCommand)) {
    execution = executeCommand(requestedCommand, {});
  }

  const actionStatus = execution
    ? execution.ok
      ? 'executed'
      : 'error'
    : requestedCommand
      ? 'blocked'
      : 'suggested';

  return {
    route: 'telemetria',
    reply: {
      text: execution?.ok
        ? `Acción ejecutada: ${requestedCommand}`
        : requestedCommand
          ? `La acción ${requestedCommand} fue detectada pero no se ejecutó o no está permitida.`
          : 'Consulta de telemetría procesada.',
      blocks: [
        {
          type: 'header',
          text: 'Telemetría'
        },
        {
          type: 'text',
          text: `Consulta recibida: ${ctx.message}`
        },
        {
          type: 'list',
          title: 'Acciones permitidas',
          items: allowedCommands
        },
        {
          type: 'action',
          action: requestedCommand || null,
          status: actionStatus,
          result: execution || null
        }
      ],
      allowedActions: allowedCommands
    }
  };
}

module.exports = { runTelemetriaSkill };
