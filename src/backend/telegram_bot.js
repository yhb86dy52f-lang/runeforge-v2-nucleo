// telegram_bot.js - Etapa 2 captura movil
// Requiere .env con TELEGRAM_BOT_TOKEN
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const TelegramBot = require('node-telegram-bot-api');

const token = process.env.TELEGRAM_BOT_TOKEN;
if(!token){ console.error('Falta TELEGRAM_BOT_TOKEN en .env'); process.exit(1); }

const parser = require('./services/bitacora_parser.js');
const ROOT = path.join(__dirname, '..', '..');
const DB_PATH = path.join(ROOT, 'data', 'runeforge.db');

async function saveParsed(parsed){
  try{
    const Database = require('better-sqlite3');
    const db = new (require('better-sqlite3'))(DB_PATH);
    db.prepare(`INSERT OR IGNORE INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash) VALUES (@fecha,@tipo,@proyecto,@texto_original,@texto_limpio,@estado,@origen,@parse_confidence,@hash)`).run({
      fecha: parsed.fecha, tipo: parsed.tipo, proyecto: parsed.proyecto,
      texto_original: parsed.texto_original, texto_limpio: parsed.texto_limpio,
      estado: parsed.estado, origen: 'telegram', parse_confidence: parsed.parse_confidence, hash: parsed.hash
    });
    db.close();
  } catch(e){
    const initSqlJs = require('sql.js');
    const SQL = await initSqlJs();
    const buf = fs.readFileSync(DB_PATH);
    const db = new SQL.Database(buf);
    try{ db.run(`INSERT OR IGNORE INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash) VALUES (?,?,?,?,?,?,?, ?,?)`, [parsed.fecha, parsed.tipo, parsed.proyecto, parsed.texto_original, parsed.texto_limpio, parsed.estado, 'telegram', parsed.parse_confidence, parsed.hash]); }catch{}
    fs.writeFileSync(DB_PATH, Buffer.from(db.export()));
  }
}

const bot = new TelegramBot(token, { polling: true });
console.log('[TELEGRAM] Bot iniciado, esperando mensajes T/P/A/H/R');

bot.on('message', async (msg)=>{
  const chatId = msg.chat.id;
  const text = (msg.text||'').trim();
  if(!text) return;
  if(text.startsWith('/start')){
    return bot.sendMessage(chatId, '⚡ Runeforge listo. Envía: T telemetria, P problema, A actividad, H habito, R tarea. Ej: P Ciner sensor km 42 fallo');
  }
  const parsed = parser.parseBitacora(text);
  if(parsed.duda){
    return bot.sendMessage(chatId, parsed.respuesta);
  }
  await saveParsed(parsed);
  bot.sendMessage(chatId, `✅ Guardado [${parsed.tipo}/${parsed.proyecto}] ${parsed.texto_limpio.slice(0,100)} (${parsed.parse_confidence})`);
});

bot.on('polling_error', (e)=> console.log('Polling error', e.message));
