const { resolveSkill } = require('./skill-router');
const { appendChatTrace } = require('./chat.trace');

async function handleChat(body) {
  const message = String(body.message || '').trim();
  const moduleHint = body.module ? String(body.module).trim() : null;
  const sessionId = body.sessionId ? String(body.sessionId).trim() : `session-${Date.now()}`;

  if (!message) {
    return {
      ok: false,
      error: 'MISSING_MESSAGE'
    };
  }

  const startedAt = new Date().toISOString();
  const skillResult = await resolveSkill({
    message,
    moduleHint,
    sessionId
  });

  const response = {
    ok: true,
    route: skillResult.route,
    sessionId,
    reply: skillResult.reply
  };

  appendChatTrace({
    ts: startedAt,
    sessionId,
    moduleHint,
    message,
    route: skillResult.route,
    reply: skillResult.reply
  });

  return response;
}

module.exports = { handleChat };