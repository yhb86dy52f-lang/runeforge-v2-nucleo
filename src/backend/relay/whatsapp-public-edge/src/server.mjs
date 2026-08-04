import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const HOST = process.env.HOST || "127.0.0.1";
const PORT = Number(process.env.PORT || 3198);
const VERIFY_TOKEN = process.env.WHATSAPP_VERIFY_TOKEN || "";
const REAL_WHATSAPP_SEND =
  String(process.env.REAL_WHATSAPP_SEND || "false").toLowerCase() === "true";

const ROOT = process.env.RUNEFORGE_ROOT || path.resolve(process.cwd(), "../..");
const DATA_DIR = path.join(ROOT, "data", "whatsapp");

function readBody(req) {
  return new Promise((resolve) => {
    let data = "";
    req.on("data", chunk => data += chunk);
    req.on("end", () => resolve(data));
  });
}

function sendJson(res, status, obj) {
  const body = JSON.stringify(obj, null, 2);
  res.writeHead(status, {"content-type":"application/json; charset=utf-8"});
  res.end(body);
}

function safeWriteTrace(prefix, obj) {
  try {
    fs.mkdirSync(DATA_DIR, { recursive: true });
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    const file = path.join(DATA_DIR, `${prefix}_${stamp}.json`);
    fs.writeFileSync(file, JSON.stringify(obj, null, 2), "utf8");
    return file;
  } catch {
    return null;
  }
}

function normalizeWebhookPayload(payload) {
  const changes = [];

  if (payload && payload.field === "messages" && payload.value) {
    changes.push({ field: payload.field, value: payload.value });
  }

  if (payload && Array.isArray(payload.entry)) {
    for (const entry of payload.entry) {
      for (const change of (entry.changes || [])) {
        changes.push(change);
      }
    }
  }

  const first = changes.find(c => c && c.field === "messages" && c.value) || null;
  const value = first ? first.value : {};

  const msg = Array.isArray(value.messages) ? value.messages[0] : null;
  const status = Array.isArray(value.statuses) ? value.statuses[0] : null;
  const contact = Array.isArray(value.contacts) ? value.contacts[0] : null;

  const text =
    msg && msg.type === "text" && msg.text
      ? String(msg.text.body || "")
      : "";

  let route = "blocked";
  let payload_type = "unknown";

  if (msg && text.trim().length > 0) {
    route = "chat_local_ai";
    payload_type = "message_text";
  } else if (status) {
    route = "status_event";
    payload_type = "status";
  }

  return {
    ok: Boolean(first),
    route,
    payload_type,
    field: first ? first.field : "unknown",
    from: msg ? msg.from : null,
    message_id: msg ? msg.id : (status ? status.id : null),
    message_type: msg ? msg.type : null,
    text_body: text,
    status: status ? status.status : null,
    recipient_id: status ? status.recipient_id : null,
    conversation_id:
      status && status.conversation ? status.conversation.id : null,
    pricing_category:
      status && status.pricing ? status.pricing.category : null,
    contact_name:
      contact && contact.profile ? contact.profile.name : null,
    phone_number_id:
      value.metadata ? value.metadata.phone_number_id : null,
    display_phone_number:
      value.metadata ? value.metadata.display_phone_number : null
  };
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || `${HOST}:${PORT}`}`);

  if (req.method === "GET" && url.pathname === "/health") {
    return sendJson(res, 200, {
      ok: true,
      service: "rf-whatsapp-public-edge",
      real_send: REAL_WHATSAPP_SEND ? "REAL_SEND_ENABLED" : "NO_REAL_SEND"
    });
  }

  if (req.method === "GET" && url.pathname === "/webhooks/whatsapp") {
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");

    if (mode === "subscribe" && token && token === VERIFY_TOKEN) {
      res.writeHead(200, {"content-type":"text/plain; charset=utf-8"});
      return res.end(challenge || "");
    }

    res.writeHead(403, {"content-type":"text/plain; charset=utf-8"});
    return res.end("VERIFY_FAILED");
  }

  if (req.method === "POST" && url.pathname === "/webhooks/whatsapp") {
    const raw = await readBody(req);
    let payload = {};

    try {
      payload = raw ? JSON.parse(raw) : {};
    } catch {}

    const normalized = normalizeWebhookPayload(payload);
    const traceFile = safeWriteTrace("rf_whatsapp_inbound_event", {
      created_at: new Date().toISOString(),
      normalized,
      payload
    });

    console.log(JSON.stringify({
      event: "RF_WHATSAPP_WEBHOOK_EVENT",
      route: normalized.route,
      payload_type: normalized.payload_type,
      status: normalized.status,
      message_type: normalized.message_type,
      real_whatsapp_send: REAL_WHATSAPP_SEND ? "REAL_SEND_ENABLED" : "NO_REAL_SEND"
    }));

    return sendJson(res, 200, {
      ok: true,
      normalized,
      trace_file: traceFile,
      forwarded_to_core: false,
      real_whatsapp_send: REAL_WHATSAPP_SEND ? "REAL_SEND_ENABLED" : "NO_REAL_SEND",
      note:
        normalized.route === "chat_local_ai"
          ? "INBOUND_TEXT_ACCEPTED_DRYRUN_NO_SEND"
          : normalized.route === "status_event"
            ? "STATUS_EVENT_ACCEPTED_DRYRUN_NO_SEND"
            : "BLOCKED_NO_TEXT_OR_STATUS"
    });
  }

  return sendJson(res, 404, { ok:false, error:"NOT_FOUND" });
});

server.listen(PORT, HOST, () => {
  console.log(JSON.stringify({
    rf_schema: "rf.whatsapp.public_edge.boot.v1",
    estado: "PUBLIC_EDGE_STATUS_EVENT_ROUTE_READY",
    host: HOST,
    port: PORT,
    real_whatsapp_send: REAL_WHATSAPP_SEND ? "REAL_SEND_ENABLED" : "NO_REAL_SEND"
  }, null, 2));
});
