const express = require('express');
const { executeCommand } = require('../../core/command-registry');

const router = express.Router();

router.post('/command', (req, res) => {
  const { command, payload } = req.body || {};

  if (!command) {
    return res.status(400).json({
      ok: false,
      error: 'MISSING_COMMAND'
    });
  }

  const result = executeCommand(command, payload || {});
  const status = result.ok ? 200 : 400;
  return res.status(status).json(result);
});

module.exports = router;
