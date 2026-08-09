const express = require('express');
const env = require('../../config/env');
const logger = require('../../shared/logger');

const router = express.Router();

router.get('/webhook', (req, res) => {
  if (!env.whatsapp.enabled) {
    return res.status(503).send('WHATSAPP_DISABLED');
  }

  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === env.whatsapp.verifyToken) {
    return res.status(200).send(challenge);
  }

  return res.status(403).send('FORBIDDEN');
});

router.post('/webhook', (req, res) => {
  if (!env.whatsapp.enabled) {
    return res.status(503).json({ ok: false, error: 'WHATSAPP_DISABLED' });
  }

  logger.info('whatsapp_webhook_received', {
    body: req.body
  });

  return res.status(200).json({ ok: true });
});

module.exports = router;
