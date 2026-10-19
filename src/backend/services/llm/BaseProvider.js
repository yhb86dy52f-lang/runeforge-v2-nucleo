class BaseProvider {
  constructor(profile = {}) {
    this.profile = profile;
    this.type = profile.type || 'unknown';
    this.enabled = profile.enabled!== false;
    this.baseUrl = this._expand(profile.baseUrl || '');
    this.timeoutMs = profile.timeoutMs || 120000;
    this.models = profile.models || {};
    this.options = profile.options || {};
  }

  _expand(value) {
    if (typeof value!== 'string') return value;
    return value.replace(/\$\{([^}:]+)(?::-([^}]*))?\}/g, (_, key, def) => {
      const env = process.env[key];
      if (env!== undefined && env!== '') return env;
      return def!== undefined? def : '';
    });
  }

  _getModel(aliasOrName) {
    if (!aliasOrName) return this.models.fast || this.models.chat || Object.values(this.models)[0];
    if (this.models[aliasOrName]) return this.models[aliasOrName];
    return aliasOrName;
  }

  async chat({ messages, model, stream = false, options = {} } = {}) {
    throw new Error(`${this.type}.chat() not implemented`);
  }

  async embed({ input, model } = {}) {
    throw new Error(`${this.type}.embed() not implemented`);
  }

  async status() {
    return { ok: this.enabled, type: this.type, baseUrl: this.baseUrl, models: this.models };
  }

  async listModels() {
    const s = await this.status();
    return Object.values(s.models || this.models);
  }

  _buildHeaders(extra = {}) {
    return { 'Content-Type': 'application/json',...extra };
  }

  async _fetchWithTimeout(url, opts = {}) {
    const controller = new AbortController();
    const t = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const res = await fetch(url, {...opts, signal: controller.signal });
      return res;
    } finally {
      clearTimeout(t);
    }
  }
}

module.exports = BaseProvider;
