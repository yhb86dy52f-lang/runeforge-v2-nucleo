const express = require('express');
const service = require('./botforce.service');

const router = express.Router();

router.get('/api/botforce/health', (req, res) => {
  res.json(service.health());
});

router.get('/api/botforce/latest', (req, res) => {
  const latest = service.latest();
  if (!latest) {
    return res.status(404).json({ ok: false, error: 'BOTFORCE_TRACE_NOT_FOUND' });
  }
  return res.json({ ok: true, ...latest });
});

router.post('/api/botforce/ingest', (req, res) => {
  try {
    const result = service.ingest(req.body || {});
    return res.status(201).json(result);
  } catch (error) {
    return res.status(500).json({
      ok: false,
      error: 'BOTFORCE_INGEST_FAILED',
      message: error.message
    });
  }
});

module.exports = router;
