const env = require('../config/env');

function executeCommand(name, payload = {}) {
  if (!env.allowedCommands.includes(name)) {
    return {
      ok: false,
      error: 'COMMAND_NOT_ALLOWED',
      command: name,
      allowedCommands: env.allowedCommands
    };
  }

  switch (name) {
    case 'ping':
      return { ok: true, command: name, result: 'pong' };

    case 'status':
      return {
        ok: true,
        command: name,
        result: {
          service: env.appName,
          env: env.nodeEnv,
          time: new Date().toISOString(),
          allowedCommands: env.allowedCommands
        }
      };

    case 'echo':
      return {
        ok: true,
        command: name,
        result: {
          echo: payload
        }
      };

    case 'time':
      return {
        ok: true,
        command: name,
        result: {
          iso: new Date().toISOString()
        }
      };

    case 'gps_status':
      return {
        ok: true,
        command: name,
        result: {
          gps: 'OK',
          time: new Date().toISOString()
        }
      };

    case 'leer_apn':
      return {
        ok: true,
        command: name,
        result: {
          apn: env.telemetria?.apn || 'PENDIENTE'
        }
      };

    case 'leer_inbound_ip':
      return {
        ok: true,
        command: name,
        result: {
          inboundIp: env.telemetria?.inboundIp || 'PENDIENTE'
        }
      };

    case 'leer_inbound_port':
      return {
        ok: true,
        command: name,
        result: {
          inboundPort: env.telemetria?.inboundPort || 'PENDIENTE'
        }
      };

    default:
      return {
        ok: false,
        error: 'COMMAND_NOT_IMPLEMENTED',
        command: name
      };
  }
}

module.exports = { executeCommand };
