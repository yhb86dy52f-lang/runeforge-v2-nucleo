const express = require('express');
const { handleChat } = require('./chat.service');

const router = express.Router();

router.post('/api/chat', async (req, res) => {
  try {
    const result = await handleChat(req.body || {});
    const status = result.ok ? 200 : 400;
    return res.status(status).json(result);
  } catch (error) {
    return res.status(500).json({
      ok: false,
      error: 'CHAT_INTERNAL_ERROR',
      message: error.message
    });
  }
});

module.exports = router;