const express = require('express');

const router = express.Router();

router.get('/api/sentinel', (req, res) => {
  res.json({
    ok: true,
    module: 'sentinel',
    status: 'idle'
  });
});

module.exports = router;
