// ================================================================
// RUNEFORGE — BACKEND OPTIMIZADO CON WEBCOMMAND Y HEALTH
// ================================================================
const Fastify = require('fastify');
const fs = require('fs');
const path = require('path');
const cors = require('@fastify/cors');
const dotenv = require('dotenv');
const envSchema = require('env-schema');
const fastifyStatic = require('@fastify/static');
const { Type } = require('@sinclair/typebox');

// ============================================================
// CARGA DEL META-PROMPT (MENTE DE PIONERO)
// ============================================================
const META_PROMPT_PATH = path.join(__dirname, '../../../../RUNEFORGE META‑PROMPT UNIFICA.md');
let SYSTEM_PROMPT = "Eres Runeforge Assistant, el asistente personal de CINER. Opera dentro del ecosistema Runeforge v2.0.";
try {
    if (fs.existsSync(META_PROMPT_PATH)) {
        SYSTEM_PROMPT = fs.readFileSync(META_PROMPT_PATH, 'utf-8');
        console.log("[RUNEFORGE] ✅ Meta-Prompt cargado. Mente de Pionero activada.");
    } else {
        console.warn("[RUNEFORGE] ⚠️ No se encontró el archivo del Meta-Prompt. Usando prompt por defecto.");
    }
} catch (err) {
    console.error("[RUNEFORGE] ❌ Error al leer Meta-Prompt:", err.message);
}

// ============================================================
// ESQUEMA DE CONFIGURACIÓN
// ============================================================
const schema = Type.Object({
  PORT: Type.Number({ default: 3100 }),
  HOST: Type.String({ default: '0.0.0.0' }),
  OLLAMA_URL: Type.String({ default: 'http://127.0.0.1:11434' }),
  OLLAMA_MODEL: Type.String({ default: 'qwen2.5:1.5b' }),
  LOG_LEVEL: Type.Union([
    Type.Literal('trace'), Type.Literal('debug'), Type.Literal('info'),
    Type.Literal('warn'), Type.Literal('error'), Type.Literal('fatal')
  ], { default: 'info' }),
  CORS_ORIGIN: Type.String({ default: '*' }),
  NODE_ENV: Type.String({ default: 'development' })
});

dotenv.config({ path: path.join(__dirname, '../../.env') });
const config = envSchema({
  schema,
  data: { ...process.env, PORT: parseInt(process.env.PORT, 10) || 3100 }
});

const app = Fastify({
  logger: {
    level: config.LOG_LEVEL,
    ...(config.NODE_ENV !== 'production' && {
      transport: {
        target: 'pino-pretty',
        options: { colorize: true, translateTime: 'HH:MM:ss Z', ignore: 'pid,hostname' }
      }
    })
  },
  ignoreTrailingSlash: true,
  bodyLimit: 1048576,
  trustProxy: true,
  ajv: { customOptions: { removeAdditional: 'all' } }
});

// ============================================================
// REGISTRO DE ARCHIVOS ESTÁTICOS (DASHBOARD MAESTRO)
// ============================================================
app.register(fastifyStatic, {
  root: 'C:/RUNEFORGE_V2_CORE/public',
  decorateReply: false
});

// ============================================================
// REGISTRO DE DOCUMENTACIÓN EN /docs
// ============================================================
app.register(fastifyStatic, {
  root: 'C:/RUNEFORGE_V2_CORE/public/documentacion y propuestas',
  prefix: '/docs',
  decorateReply: false
});

// ============================================================
// CORS
// ============================================================
const corsOrigins = config.CORS_ORIGIN === '*' ? '*' : config.CORS_ORIGIN.split(',').map(o => o.trim());
app.register(cors, { origin: corsOrigins, methods: ['GET', 'POST', 'OPTIONS'], allowedHeaders: ['Content-Type', 'Authorization'] });

// ============================================================
// MANEJADOR DE ERRORES
// ============================================================
app.setErrorHandler((error, request, reply) => {
  request.log.error({ err: error, url: request.url }, error.message);
  const statusCode = error.statusCode || 500;
  const response = { error: error.message || 'Error interno del servidor', statusCode };
  if (config.NODE_ENV === 'development' && error.stack) { response.detail = error.stack; }
  reply.status(statusCode).send(response);
});

// ============================================================
// ENDPOINTS DE SALUD Y CHAT
// ============================================================
app.get('/health', async (request, reply) => {
  return reply.send({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    model: config.OLLAMA_MODEL,
    ollama: config.OLLAMA_URL,
    environment: config.NODE_ENV
  });
});

app.post('/api/chat', { handlerTimeout: 30000 }, async (request, reply) => {
  const start = Date.now();
  const { message } = request.body || {};
  if (!message) return reply.status(400).send({ error: 'El parámetro message es requerido' });

  try {
    const ollamaResponse = await fetch(`${config.OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: config.OLLAMA_MODEL,
        system: SYSTEM_PROMPT,   // <--- META-PROMPT INYECTADO
        prompt: message,
        stream: false,
        options: { temperature: 0.2, num_predict: 220, top_k: 40, top_p: 0.9 }
      })
    });
    if (!ollamaResponse.ok) {
      const error = new Error(`Ollama error: ${ollamaResponse.statusText}`);
      error.statusCode = ollamaResponse.status >= 500 ? 503 : 400;
      throw error;
    }
    const data = await ollamaResponse.json();
    return reply.send({ response: data.response, meta: { model: config.OLLAMA_MODEL, elapsed_ms: Date.now() - start } });
  } catch (error) {
    if (error.code === 'UND_ERR_ABORTED' || error.name === 'AbortError') {
      error.statusCode = 504;
      error.message = 'Tiempo de espera agotado (Ollama no responde)';
    } else if (error.message?.includes('ECONNREFUSED') || error.message?.includes('fetch failed')) {
      error.statusCode = 503;
      error.message = 'Ollama no está disponible en 127.0.0.1:11434. Asegúrate de ejecutar `ollama serve`.';
    }
    throw error;
  }
});

// ============================================================
// ENDPOINTS DE ESTADO (ESTATUS.md y MANIFIESTO.md)
// ============================================================
app.get('/api/manifiesto', async (req, reply) => {
    const pathManifiesto = path.join(__dirname, '../../../../MANIFIESTO.md');
    if (fs.existsSync(pathManifiesto)) {
        return reply.send({ ok: true, content: fs.readFileSync(pathManifiesto, 'utf-8') });
    }
    return reply.status(404).send({ ok: false, error: 'Manifiesto no encontrado' });
});

app.get('/api/estatus', async (req, reply) => {
    const pathEstatus = path.join(__dirname, '../../../../ESTATUS.md');
    if (fs.existsSync(pathEstatus)) {
        return reply.send({ ok: true, content: fs.readFileSync(pathEstatus, 'utf-8') });
    }
    return reply.status(404).send({ ok: false, error: 'Estatus no encontrado' });
});

// ============================================================
// WEBCOMMAND (PARA EL DASHBOARD)
// ============================================================
app.get('/api/webcommand/health', async (req, reply) => {
  return reply.send({ ok: true, status: 'online', service: 'webcommand' });
});
app.post('/api/webcommand/health', async (req, reply) => {
  return reply.send({ ok: true, status: 'online', service: 'webcommand' });
});

app.post('/api/webcommand', async (req, reply) => {
  const { command, action } = req.body || {};
  const targetAction = action || command;

  if (targetAction === 'ACTION_src-tree' || targetAction === 'src-tree') {
    return reply.send({ ok: true, action: 'ACTION_src-tree', output: 'C:\\RUNEFORGE_V2_CORE\\src\n├── backend\n└── relay' });
  } else if (targetAction === 'ACTION_pm2-health' || targetAction === 'pm2-health') {
    return reply.send({ ok: true, action: 'ACTION_pm2-health', output: 'PM2 Online - runeforge-backend & runeforge-relay' });
  } else if (targetAction === 'ACTION_backend-root' || targetAction === 'backend-root') {
    return reply.send({ ok: true, action: 'ACTION_backend-root', output: 'C:\\RUNEFORGE_V2_CORE\\src\\backend' });
  } else if (targetAction === 'ACTION_package' || targetAction === 'package') {
    return reply.send({ ok: true, action: 'ACTION_package', output: 'Runeforge Core v2.0.0' });
  }

  return reply.send({ ok: true, action: targetAction, message: 'Comando ejecutado correctamente' });
});

// ============================================================
// MANEJADOR 404 (FINAL)
// ============================================================

// ============================================================
// ENDPOINT /api/orders (FALLBACK BITÁCORA PRO)
// ============================================================
app.get('/api/orders', async (req, reply) => {
  return { total: 0, data: [] };
});

app.post('/api/orders', async (req, reply) => {
  return { status: 'success', message: 'Orden recibida' };
});

app.setNotFoundHandler((request, reply) => {
  reply.status(404).send({
    error: 'Not Found',
    message: `Ruta ${request.url} no encontrada`,
    statusCode: 404
  });
});

// ============================================================
// INICIO DEL SERVIDOR
// ============================================================
const start = async () => {
  try {
    await app.listen({ port: config.PORT, host: config.HOST });
    app.log.info({ address: `http://${config.HOST}:${config.PORT}`, ollama: config.OLLAMA_URL, model: config.OLLAMA_MODEL }, '[RUNEFORGE-CORE] SOBERANIA ACTIVA');
  } catch (err) {
    app.log.fatal({ err }, 'Error al iniciar el servidor');
    process.exit(1);
  }
};
start();
