const express = require('express');
const env = require('../../config/env');
const { getAiStatus } = require('../../adapters/ai/ai.client');

const router = express.Router();

router.get('/', (req, res) => {
  res.type('html').send(`
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${env.appName}</title>
  <style>
    body { font-family: Arial, sans-serif; background:#0e1016; color:#e6e6e6; margin:0; }
    .wrap { max-width: 960px; margin: 32px auto; padding: 24px; }
    .card { background:#171b24; border:1px solid #2a3242; border-radius:16px; padding:20px; margin-bottom:16px; }
    code { background:#11151d; padding:2px 6px; border-radius:6px; }
    .muted { color:#9aa3b2; }
    h1,h2 { margin-top:0; }
    ul { line-height:1.7; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="card">
      <h1>${env.appName}</h1>
      <p class="muted">MVP local-first operativo.</p>
    </div>
    <div class="card">
      <h2>Beacon</h2>
      <ul>
        <li><code>GET /health</code></li>
        <li><code>GET /status</code></li>
      </ul>
    </div>
    <div class="card">
      <h2>Relay</h2>
      <ul>
        <li><code>POST /command</code></li>
        <li><code>GET /api/relay/whatsapp/webhook</code></li>
        <li><code>POST /api/relay/whatsapp/webhook</code></li>
      </ul>
    </div>
    <div class="card">
      <h2>AI</h2>
      <pre>${JSON.stringify(getAiStatus(), null, 2)}</pre>
    </div>
  </div>
</body>
</html>`);
});

router.get('/api/forge', (req, res) => {
  res.json({
    ok: true,
    module: 'forge',
    ai: getAiStatus(),
    commands: env.allowedCommands
  });
});

module.exports = router;
