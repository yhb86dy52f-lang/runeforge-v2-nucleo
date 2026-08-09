const express = require('express');
const path = require('path');
const beaconRoutes = require('./modules/beacon/beacon.routes');
const relayRoutes = require('./modules/relay/relay.routes');
const forgeRoutes = require('./modules/forge/forge.routes');
const sentinelRoutes = require('./modules/sentinel/sentinel.routes');
const codexRoutes = require('./modules/codex/codex.routes');
const chatRoutes = require('./modules/chat/chat.routes');
const globalChatRoutes = require('./modules/global_chat/global_chat.routes');
const botforceRoutes = require('./modules/botforce/botforce.routes');
const n8nIntegrationRoutes = require('./modules/integrations/n8n.routes');
const whatsappWebhookRoutes = require('./adapters/whatsapp/whatsapp.webhook.routes');
const webcommandRoutes = require('./modules/webcommand/webcommand.routes');
const { traceRequest } = require('./modules/trace/trace.middleware');

const app = express();
// === RF_LOCAL_AI_ASSISTANT_ENDPOINT_CURRENT_BEGIN ===
const localAiRoutes = require("./modules/local_ai/local_ai.routes");
app.use("/api/ai/local", localAiRoutes);
// === RF_LOCAL_AI_ASSISTANT_ENDPOINT_CURRENT_END ===

app.use(express.json({ limit: '1mb' }));
app.use(traceRequest);

app.use('/', forgeRoutes);
app.use('/', beaconRoutes);
app.use('/', relayRoutes);
app.use('/', sentinelRoutes);
app.use('/', codexRoutes);
app.use('/', chatRoutes);
app.use('/', globalChatRoutes);
app.use('/', botforceRoutes);
app.use('/', n8nIntegrationRoutes);
app.use('/', webcommandRoutes);
app.use('/api/relay/whatsapp', whatsappWebhookRoutes);



// === RF_FORGE_UI_STATIC_ROUTE_V1_BEGIN ===
// Serve Forge UI from local public folder. No shell. No secrets. No redirect loop.
const forgeIndexPath = path.join(__dirname, '..', 'public', 'forge', 'index.html');

app.get(['/forge', '/forge/'], (req, res) => {
  res.sendFile(forgeIndexPath);
});
// === RF_FORGE_UI_STATIC_ROUTE_V1_END ===

app.use((req, res) => {
  res.status(404).json({
    ok: false,
    error: 'NOT_FOUND',
    path: req.originalUrl
  });
});

module.exports = app;



