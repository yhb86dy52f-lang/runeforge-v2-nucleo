const fs = require('fs');
const path = require('path');

const logDir = path.resolve(process.cwd(), 'data/logs');
const logFile = path.join(logDir, 'runeforge.log');

function ensureLogDir() {
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }
}

function write(level, message, meta = {}) {
  ensureLogDir();
  const row = {
    ts: new Date().toISOString(),
    level,
    message,
    meta
  };
  fs.appendFileSync(logFile, JSON.stringify(row) + '\n', 'utf8');
  console.log(JSON.stringify(row));
}

module.exports = {
  info: (message, meta) => write('info', message, meta),
  warn: (message, meta) => write('warn', message, meta),
  error: (message, meta) => write('error', message, meta)
};
