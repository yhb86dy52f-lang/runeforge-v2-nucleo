const fs = require('fs');
const path = require('path');

const traceDir = path.join(process.cwd(), 'data', 'trace');
const traceFile = path.join(traceDir, 'chat.log');

function appendChatTrace(entry) {
  fs.mkdirSync(traceDir, { recursive: true });
  fs.appendFileSync(traceFile, JSON.stringify(entry) + '\n', 'utf8');
}

module.exports = { appendChatTrace };
