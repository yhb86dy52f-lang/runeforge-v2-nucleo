const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

function parseList(value, fallback = '') {
  return (value || fallback)
    .split(',')
    .map(v => v.trim())
    .filter(Boolean);
}

module.exports = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 3100),
  host: process.env.RUNEFORGE_HOST || process.env.HOST || '127.0.0.1',
  appName: process.env.RUNEFORGE_NAME || 'Runeforge',
  allowedCommands: parseList(process.env.RUNEFORGE_ALLOWED_COMMANDS, 'ping,status,echo,time'),
  ai: {
    provider: process.env.AI_PROVIDER || '',
    apiKey: process.env.AI_API_KEY || '',
    model: process.env.AI_MODEL || ''
  },
  telemetria: {
    apn: process.env.RUNEFORGE_DEFAULT_APN || 'PENDIENTE',
    inboundIp: process.env.RUNEFORGE_DEFAULT_INBOUND_IP || 'PENDIENTE',
    inboundPort: process.env.RUNEFORGE_DEFAULT_INBOUND_PORT || 'PENDIENTE'
  },
  whatsapp: {
    enabled: String(process.env.WHATSAPP_ENABLED || 'false').toLowerCase() === 'true',
    verifyToken: process.env.WHATSAPP_VERIFY_TOKEN || '',
    accessToken: process.env.WHATSAPP_ACCESS_TOKEN || '',
    phoneNumberId: process.env.WHATSAPP_PHONE_NUMBER_ID || '',
    appSecret: process.env.WHATSAPP_APP_SECRET || ''
  }
};

