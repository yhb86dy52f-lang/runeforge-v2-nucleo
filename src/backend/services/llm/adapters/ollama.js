const BaseProvider = require('../BaseProvider');
class OllamaProvider extends BaseProvider {
  constructor(profile = {}) {
    super(profile);
    this.type = 'ollama';
    this.baseUrl = this._expand(profile.baseUrl || process.env.OLLAMA_BASE_URL || 'http://127.0.0.1:11434');
    this.keepAlive = this._expand(profile.keepAlive || process.env.OLLAMA_KEEP_ALIVE || '10m');
  }
  async status() {
    try {
      const res = await this._fetchWithTimeout(`${this.baseUrl}/api/tags`, { method: 'GET' });
      if (!res.ok) return { ok: false, type: this.type, error: `HTTP ${res.status}`, baseUrl: this.baseUrl };
      const data = await res.json();
      const count = (data.models || []).length;
      return { ok: true, type: this.type, baseUrl: this.baseUrl, count, models: data.models, profileModels: this.models };
    } catch (e) {
      return { ok: false, type: this.type, baseUrl: this.baseUrl, error: e.message };
    }
  }
  async listModels() {
    const s = await this.status();
    return s.models || [];
  }
  async chat({ messages, model, stream = false, options = {} } = {}) {
    const modelName = this._getModel(model);
    const body = {
      model: modelName,
      messages: messages || [{ role: 'user', content: 'ping' }],
      stream: !!stream,
      keep_alive: this.keepAlive,
      options: { ...this.options, ...options }
    };
    const res = await this._fetchWithTimeout(`${this.baseUrl}/api/chat`, {
      method: 'POST',
      headers: this._buildHeaders(),
      body: JSON.stringify(body)
    });
    if (!res.ok) {
      const txt = await res.text().catch(() => '');
      throw new Error(`Ollama chat failed ${res.status}: ${txt}`);
    }
    if (stream) return res;
    const data = await res.json();
    return {
      role: data.message?.role || 'assistant',
      content: data.message?.content || '',
      model: data.model || modelName,
      raw: data,
      eval_count: data.eval_count,
      eval_duration: data.eval_duration
    };
  }
  async embed({ input, model } = {}) {
    const modelName = this._getModel(model || 'embed');
    const body = {
      model: modelName,
      input: Array.isArray(input) ? input.join('\n') : String(input || ''),
      keep_alive: this.keepAlive
    };
    const res = await this._fetchWithTimeout(`${this.baseUrl}/api/embed`, {
      method: 'POST',
      headers: this._buildHeaders(),
      body: JSON.stringify(body)
    });
    if (!res.ok) {
      const txt = await res.text().catch(() => '');
      throw new Error(`Ollama embed failed ${res.status}: ${txt}`);
    }
    const data = await res.json();
    return { embedding: data.embeddings?.[0] || data.embedding, model: modelName, raw: data };
  }
  async generate({ prompt, model, options = {} } = {}) {
    const modelName = this._getModel(model);
    const body = {
      model: modelName,
      prompt: String(prompt || ''),
      stream: false,
      keep_alive: this.keepAlive,
      options: { ...this.options, ...options }
    };
    const res = await this._fetchWithTimeout(`${this.baseUrl}/api/generate`, {
      method: 'POST',
      headers: this._buildHeaders(),
      body: JSON.stringify(body)
    });
    if (!res.ok) {
      const txt = await res.text().catch(() => '');
      throw new Error(`Ollama generate failed ${res.status}: ${txt}`);
    }
    const data = await res.json();
    return { content: data.response || '', model: data.model || modelName, raw: data };
  }
}
module.exports = OllamaProvider;
