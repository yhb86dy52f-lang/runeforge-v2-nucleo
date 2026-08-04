const fs = require("fs");
const path = require("path");

const OLLAMA_BASE_URL = process.env.OLLAMA_BASE_URL || "http://127.0.0.1:11434";
const DEFAULT_MODEL = process.env.RF_LOCAL_AI_MODEL || "qwen2.5:1.5b";
const TRACE_FILE = process.env.RF_LOCAL_AI_TRACE_FILE || path.resolve(process.cwd(), "..", "data", "local_ai", "traces", "rf_local_ai_chat_current.jsonl");
const MAX_INPUT_CHARS = Number(process.env.RF_LOCAL_AI_MAX_INPUT_CHARS || 8000);

function nowIso() {
  return new Date().toISOString();
}

function safeString(value, max = MAX_INPUT_CHARS) {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, max);
}

function appendTrace(entry) {
  const dir = path.dirname(TRACE_FILE);
  fs.mkdirSync(dir, { recursive: true });
  fs.appendFileSync(TRACE_FILE, JSON.stringify(entry) + "\n", "utf8");
}

async function listModels() {
  const response = await fetch(OLLAMA_BASE_URL + "/api/tags", { method: "GET" });
  if (!response.ok) {
    throw new Error("OLLAMA_TAGS_HTTP_" + response.status);
  }
  const data = await response.json();
  return Array.isArray(data.models) ? data.models.map((item) => item.name) : [];
}

async function health() {
  const models = await listModels();
  const model = process.env.RF_LOCAL_AI_MODEL || DEFAULT_MODEL;
  return {
    ok: models.includes(model),
    service: "Runeforge Local AI",
    provider: "ollama",
    baseUrl: OLLAMA_BASE_URL,
    model,
    models,
    policy: {
      shell: "BLOCKED",
      powershell: "BLOCKED",
      secrets: "NO_READ",
      external_api: "BLOCKED",
      trace: "JSONL_ONLY"
    },
    ts: nowIso()
  };
}

function buildSystemPrompt(extraSystem) {
  const base = [
    "Eres Runeforge Local AI Assistant.",
    "Responde en español claro, técnico y accionable.",
    "Respeta la arquitectura INPUT → ROUTER → SKILL → ACTION → TRACE → RESPONSE.",
    "No ejecutes comandos. No inventes rutas. No pidas secretos.",
    "Si una acción toca sistema, responde con plan controlado y trazable.",
    "Prioridad: local-first, backend-first, seguridad por defecto."
  ].join(" ");
  const extra = safeString(extraSystem, 2000);
  return extra ? base + " " + extra : base;
}

async function chat(payload) {
  const message = safeString(payload.message || payload.prompt || payload.input || "");
  const system = buildSystemPrompt(payload.system || "");
  const model = safeString(payload.model || process.env.RF_LOCAL_AI_MODEL || DEFAULT_MODEL, 120) || DEFAULT_MODEL;

  const traceBase = {
    schema: "rf.local_ai.chat.v1",
    ts: nowIso(),
    model,
    input_chars: message.length,
    policy: {
      shell: "BLOCKED",
      powershell: "BLOCKED",
      secrets: "NO_READ",
      external_api: "BLOCKED",
      trace: "JSONL_ONLY"
    }
  };

  if (!message) {
    const blocked = {
      ...traceBase,
      ok: false,
      status: "BLOCKED",
      reason: "EMPTY_MESSAGE"
    };
    appendTrace(blocked);
    return blocked;
  }

  const body = {
    model,
    messages: [
      { role: "system", content: system },
      { role: "user", content: message }
    ],
    stream: false
  };

  const started = Date.now();

  try {
    const response = await fetch(OLLAMA_BASE_URL + "/api/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body)
    });

    if (!response.ok) {
      throw new Error("OLLAMA_CHAT_HTTP_" + response.status);
    }

    const data = await response.json();
    const content = data && data.message && typeof data.message.content === "string" ? data.message.content : "";

    const result = {
      ...traceBase,
      ok: true,
      status: "OK",
      elapsed_ms: Date.now() - started,
      response_chars: content.length,
      content
    };

    appendTrace(result);
    return result;
  } catch (error) {
    const result = {
      ...traceBase,
      ok: false,
      status: "ERROR",
      elapsed_ms: Date.now() - started,
      error: error.message
    };
    appendTrace(result);
    return result;
  }
}

module.exports = {
  health,
  chat,
  listModels
};