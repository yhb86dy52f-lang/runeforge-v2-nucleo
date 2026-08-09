const express = require("express");
const localAi = require("./local_ai.service");

const router = express.Router();

router.use(express.json({ limit: "32kb" }));

router.get("/health", async (_req, res) => {
  try {
    const result = await localAi.health();
    res.status(result.service ? 200 : 503).json(result);
  } catch (error) {
    res.status(503).json({ ok:false, service:"Runeforge Local AI", error:error.message, ts:new Date().toISOString() });
  }
});

router.get("/smoke", async (_req, res) => {
  try {
    const result = await localAi.chat({ message:"Responde solo OK", model:"qwen2.5:1.5b", num_predict:8, temperature:0 });
    res.status(result.ok ? 200 : 500).json(result);
  } catch (error) {
    res.status(500).json({ ok:false, status:"ERROR", error:error.message, ts:new Date().toISOString() });
  }
});

router.post("/chat", async (req, res) => {
  try {
    const result = await localAi.chat(req.body || {});
    res.status(result.ok ? 200 : 500).json(result);
  } catch (error) {
    res.status(500).json({ ok:false, status:"ERROR", error:error.message, ts:new Date().toISOString() });
  }
});

module.exports = router;
