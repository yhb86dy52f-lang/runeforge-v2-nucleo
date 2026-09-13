const fs = require('fs');
const path = require('path');
const BaseProvider = require('./BaseProvider');
const OllamaProvider = require('./adapters/ollama');
function expandEnvVars(value) {
  if (typeof value === 'string') {
    return value.replace(/\$\{([^}:]+)(?::-([^}]*))?\}/g, (_, key, def) => {
      const env = process.env[key];
      if (env !== undefined && env !== '') return env;
      return def !== undefined ? def : '';
    });
  }
  if (Array.isArray(value)) return value.map(expandEnvVars);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = expandEnvVars(v);
    return out;
  }
  return value;
}
function loadEnvFile(envPath) {
  try {
    if (!fs.existsSync(envPath)) return;
    const content = fs.readFileSync(envPath, 'utf8');
    for (const line of content.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eq = trimmed.indexOf('=');
      if (eq === -1) continue;
      const key = trimmed.slice(0, eq).trim();
      let val = trimmed.slice(eq + 1).trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      if (process.env[key] === undefined) process.env[key] = val;
    }
  } catch (_) {}
}
function loadProfiles(profilesPath) {
  const candidates = [
    profilesPath,
    path.join(process.cwd(), 'config', 'llm-profiles.json'),
    path.join(__dirname, '..', '..', '..', '..', 'config', 'llm-profiles.json'),
    path.join(__dirname, '..', '..', 'config', 'llm-profiles.json'),
    path.join(__dirname, '../../../config/llm-profiles.json')
  ].filter(Boolean);
  let raw = null;
  let usedPath = null;
  for (const p of candidates) {
    try {
      if (p && fs.existsSync(p)) {
        raw = fs.readFileSync(p, 'utf8');
        usedPath = p;
        break;
      }
    } catch (_) {}
  }
  if (!raw) {
    return {
      defaultProvider: 'ollama',
      profiles: {
        ollama: {
          type: 'ollama',
          enabled: true,
          baseUrl: '${OLLAMA_BASE_URL:-http://127.0.0.1:11434}',
          keepAlive: '10m',
          models: { fast: 'qwen2.5:1.5b', chat: 'gemma2:2b', code: 'deepseek-coder', embed: 'nomic-embed-text' }
        }
      }
    };
  }
  try {
    const parsed = JSON.parse(raw);
    return expandEnvVars(parsed);
  } catch (e) {
    throw new Error(`Failed to parse llm-profiles.json at ${usedPath}: ${e.message}`);
  }
}
function resolveProviderType(type) {
  const map = {
    'ollama': OllamaProvider,
    'openai-compatible': BaseProvider,
    'gemini': BaseProvider,
    'meta-whatsapp': BaseProvider
  };
  return map[type] || BaseProvider;
}
function createProvider(nameOrAlias, overrides = {}) {
  loadEnvFile(path.join(process.cwd(), '.env'));
  loadEnvFile(path.join(process.cwd(), 'config', '.env'));
  const all = loadProfiles(overrides.profilesPath);
  const profiles = all.profiles || all.profiles === undefined ? all.profiles : all;
  const routing = all.routing || {};
  let providerKey = nameOrAlias;
  let modelAlias = null;
  if (nameOrAlias && nameOrAlias.includes(':')) {
    const parts = nameOrAlias.split(':');
    providerKey = parts[0];
    modelAlias = parts[1];
  }
  if (routing[providerKey]) {
    const routed = routing[providerKey];
    if (routed.includes(':')) {
      const [rk, rm] = routed.split(':');
      providerKey = rk;
      modelAlias = modelAlias || rm;
    } else {
      providerKey = routed;
    }
  }
  if (!providerKey) providerKey = all.defaultProvider || 'ollama';
  let profile = profiles[providerKey];
  if (!profile) {
    const fallbackKey = all.defaultProvider || 'ollama';
    profile = profiles[fallbackKey];
    providerKey = fallbackKey;
  }
  if (!profile) throw new Error(`Provider profile not found: ${nameOrAlias}`);
  const merged = expandEnvVars({ ...profile, ...overrides, models: { ...(profile.models || {}), ...(overrides.models || {}) } });
  if (modelAlias && merged.models && merged.models[modelAlias]) {
    merged._selectedModel = merged.models[modelAlias];
    merged._selectedModelAlias = modelAlias;
  } else if (modelAlias) {
    merged._selectedModel = modelAlias;
    merged._selectedModelAlias = modelAlias;
  }
  const ProviderClass = resolveProviderType(merged.type);
  const instance = new ProviderClass(merged);
  if (merged.type === 'ollama') {
    return instance;
  }
  if (merged.enabled === false) {
    const ollamaFallback = profiles['ollama'] || profiles[all.defaultProvider];
    if (ollamaFallback) {
      return new OllamaProvider(expandEnvVars(ollamaFallback));
    }
  }
  return instance;
}
function createProviderFromEnv() {
  return createProvider(process.env.LLM_PROVIDER || process.env.DEFAULT_LLM || 'ollama');
}
module.exports = { loadProfiles, createProvider, createProviderFromEnv, expandEnvVars };
