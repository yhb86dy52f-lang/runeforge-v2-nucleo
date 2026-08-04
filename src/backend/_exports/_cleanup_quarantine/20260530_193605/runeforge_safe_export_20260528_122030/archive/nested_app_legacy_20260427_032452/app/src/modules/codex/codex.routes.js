const express = require('express');

const router = express.Router();

router.get('/api/codex', (req, res) => {
  res.json({
    ok: true,
    module: 'codex',
    docs: []
  });
});

module.exports = router;
