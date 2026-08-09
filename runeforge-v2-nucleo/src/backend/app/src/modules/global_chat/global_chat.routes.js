const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const router = express.Router();

const RF_ROOT = 'C:\\RUNEFOGE_PRO\\runeforge';
const DATA_DIR = path.join(RF_ROOT, 'data', 'global_chat');
const JSONL_DIR = path.join(DATA_DIR, 'jsonl');
const INBOX_DIR = path.join(DATA_DIR, 'inbox');

function ensureDirs() {
  fs.mkdirSync(JSONL_DIR, { recursive: true });
  fs.mkdirSync(INBOX_DIR, { recursive: true });
}

function todayStamp() {
  const d = new Date();
  return d.toISOString().slice(0, 10).replace(/-/g, '');
}

function makeId(prefix) {
  return `${prefix}-${new Date().toISOString().replace(/[:.]/g, '-')}-${crypto.randomBytes(3).toString('hex')}`;
}

function cleanText(value) {
  return String(value || '').replace(/\s+/g, ' ').trim();
}

function classify(text) {
  const t = text.toLowerCase();
  if (t.includes('powershell') || t.includes('pm2') || t.includes('endpoint') || t.includes('backend')) return 'technical';
  if (t.includes('bitácora') || t.includes('bitacora') || t.includes('falla') || t.includes('incidente')) return 'memory_ops';
  if (t.includes('optimiza') || t.includes('arquitectura') || t.includes('infraestructura')) return 'architecture';
  return 'general';
}

function riskLevel(text) {
  const t = text.toLowerCase();
  if (t.includes('.env') || t.includes('token') || t.includes('secret') || t.includes('password')) return 'alto';
  if (t.includes('borrar') || t.includes('delete') || t.includes('firewall') || t.includes('run_powershell')) return 'medio';
  return 'bajo';
}

function appendJsonl(kind, obj) {
  ensureDirs();
  const file = path.join(JSONL_DIR, `${kind}_${todayStamp()}.jsonl`);
  fs.appendFileSync(file, JSON.stringify(obj) + '\n', 'utf8');
  return file;
}

router.get('/api/chat/global/health', (req, res) => {
  ensureDirs();
  res.json({
    ok: true,
    service: 'RF_GLOBAL_CHAT_CORE_V1',
    mode: 'mvp_trace_only',
    shell: false,
    actions: false,
    storage: {
      jsonl: JSONL_DIR,
      inbox: INBOX_DIR
    },
    endpoints: [
      'POST /api/chat/global',
      'GET /api/chat/global/health',
      'GET /api/chat/global/recent',
      'POST /api/chat/global/trace'
    ],
    ts: new Date().toISOString()
  });
});

router.post('/api/chat/global', (req, res) => {
  const body = req.body && typeof req.body === 'object' ? req.body : {};
  const raw = cleanText(body.message || body.text || body.message_raw || '');
  const source = cleanText(body.source || 'unknown');
  const channel = cleanText(body.channel || 'unknown');
  const project = cleanText(body.project || 'runeforge');

  if (!raw) {
    return res.status(400).json({
      ok: false,
      error: 'MESSAGE_REQUIRED',
      module: 'RF_GLOBAL_CHAT_CORE_V1'
    });
  }

  const chatId = cleanText(body.chat_id || makeId('rf-chat'));
  const turnId = cleanText(body.turn_id || makeId('rf-turn'));
  const kind = classify(raw);
  const risk = riskLevel(raw);

  const envelope = {
    schema: 'rf.global_chat.v1',
    chat_id: chatId,
    turn_id: turnId,
    timestamp: new Date().toISOString(),
    source,
    channel,
    user_intent: kind,
    mode: kind,
    risk_level: risk,
    project,
    environment: cleanText(body.environment || 'lab'),
    message_raw: raw,
    message_normalized: raw,
    classification: {
      type: kind,
      needs_action: false,
      needs_memory: true,
      needs_command: false
    },
    routing: {
      target: 'RF_GLOBAL_CHAT_CORE_V1',
      allowed_actions: ['trace_event', 'memory_write', 'health_check_request'],
      blocked_actions: ['run_powershell', 'shell', 'secrets_read']
    },
    memory: {
      save_summary: true,
      save_raw: false,
      obsidian_note: false,
      sqlite_index: false
    },
    trace: {
      status: 'created',
      trace_file: null
    }
  };

  const traceFile = appendJsonl('rf_global_chat_ingest', envelope);
  envelope.trace.trace_file = traceFile;

  res.json({
    ok: true,
    service: 'RF_GLOBAL_CHAT_CORE_V1',
    status: 'INGESTED_TRACE_ONLY',
    envelope,
    shell: false,
    actions_executed: false,
    ts: new Date().toISOString()
  });
});

router.post('/api/chat/global/trace', (req, res) => {
  const body = req.body && typeof req.body === 'object' ? req.body : {};
  const event = cleanText(body.event || 'rf_global_chat_trace');
  const trace = {
    timestamp: new Date().toISOString(),
    event: event.replace(/[^a-zA-Z0-9_\-:.]/g, '_').slice(0, 80),
    source: cleanText(body.source || 'unknown'),
    payload: body.payload || {},
    module: 'RF_GLOBAL_CHAT_CORE_V1',
    shell: false
  };
  const traceFile = appendJsonl('rf_global_chat_trace', trace);
  res.json({ ok: true, status: 'TRACE_WRITTEN', trace_file: traceFile, trace });
});

router.get('/api/chat/global/recent', (req, res) => {
  ensureDirs();
  const files = fs.readdirSync(JSONL_DIR)
    .filter(f => f.endsWith('.jsonl'))
    .map(f => path.join(JSONL_DIR, f))
    .sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs)
    .slice(0, 5);

  const rows = [];
  for (const file of files) {
    const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/).filter(Boolean).slice(-10);
    for (const line of lines) {
      try {
        const obj = JSON.parse(line);
        rows.push({
          file,
          timestamp: obj.timestamp || obj.ts || null,
          event: obj.event || obj.user_intent || obj.schema || null,
          source: obj.source || null,
          channel: obj.channel || null,
          risk_level: obj.risk_level || null
        });
      } catch (_) {}
    }
  }

  res.json({
    ok: true,
    service: 'RF_GLOBAL_CHAT_CORE_V1',
    count: rows.length,
    recent: rows.slice(-20).reverse()
  });
});

module.exports = router;