/**
 * RUNEFORGE v2.0 - PM2 Ecosystem
 * Gestiona backend Fastify :3100 y relay WhatsApp :3198
 * Filosofía: Local-First, Bajo Consumo, Soberanía Digital
 * 
 * Uso:
 * pm2 start ecosystem.config.js --env development
 * pm2 list | pm2 monit | pm2 logs runeforge-backend
 */

module.exports = {
  apps: [
    {
      name: "runeforge-backend",
      script: "src/backend/app/src/server.js",
      cwd: "C:\\RUNEFORGE_V2_CORE",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      watch: false,
      max_memory_restart: "300M",
      env: {
        NODE_ENV: "development",
        PORT: 3100,
        OLLAMA_HOST: "http://127.0.0.1:11434",
        OLLAMA_MODEL: "qwen2.5:1.5b"
      },
      env_production: {
        NODE_ENV: "production",
        PORT: 3100,
        OLLAMA_HOST: "http://127.0.0.1:11434",
        OLLAMA_MODEL: "qwen2.5:1.5b"
      },
      error_file: "logs/backend-error.log",
      out_file: "logs/backend-out.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      merge_logs: true
    },
    {
      name: "runeforge-relay",
      script: "src/relay/server.js",
      cwd: "C:\\RUNEFORGE_V2_CORE",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      watch: false,
      max_memory_restart: "150M",
      env: {
        NODE_ENV: "development",
        PORT: 3198
      },
      error_file: "logs/relay-error.log",
      out_file: "logs/relay-out.log",
      log_date_format: "YYYY-MM-DD HH:mm:ss",
      merge_logs: true
    }
  ]
};
