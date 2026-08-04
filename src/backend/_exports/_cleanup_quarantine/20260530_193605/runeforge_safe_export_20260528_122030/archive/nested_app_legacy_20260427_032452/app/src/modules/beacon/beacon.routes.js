const express = require('express');
const env = require('../../config/env');

const router = express.Router();

router.get('/health', (req, res) => {
  res.json({
    ok: true,
    service: env.appName,
    env: env.nodeEnv,
    uptimeSec: Math.round(process.uptime())
  });
});

router.get('/status', (req, res) => {
  res.json({
    ok: true,
    service: env.appName,
    node: process.version,
    platform: process.platform,
    pid: process.pid,
    cwd: process.cwd(),
    time: new Date().toISOString()
  });
});

module.exports = router;
