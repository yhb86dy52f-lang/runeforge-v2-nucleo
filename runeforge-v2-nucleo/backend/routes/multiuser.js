module.exports = async function (fastify) {
  const users = new Map();
  fastify.post('/api/multiuser/join', async (req) => {
    const { name, deviceId } = req.body;
    const id = deviceId || Math.random().toString(36).slice(2);
    users.set(id, { id, name, lastSeen: Date.now(), actions: [] });
    return { ok: true, id, ip: req.ip, server: 'RUNE-BOX v2.5 LAN' };
  });
  fastify.post('/api/multiuser/action', async (req) => {
    const { deviceId, type, payload } = req.body;
    const u = users.get(deviceId);
    if (!u) return { ok: false };
    u.actions.push({ type, payload, ts: Date.now() });
    const fs = require('fs'); 
    if(!fs.existsSync('data/traces')) fs.mkdirSync('data/traces',{recursive:true});
    fs.appendFileSync('data/traces/multiuser.jsonl', JSON.stringify({ deviceId, type, payload, ts: Date.now() })+'\n');
    return { ok: true };
  });
  fastify.get('/api/multiuser/list', async () => { return { users: Array.from(users.values()) } });
  fastify.post('/api/sync', async (req) => { return { ok: true, merged: req.body?.queue?.length || 0 } });
}
