module.exports = {
  apps: [
    {
      name: "runeforge-backend",
      script: "./server.js",
      cwd: "C:\RUNEFORGE_V2_CORE",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: "5s",
      env: { PORT: 3100, NODE_ENV: "production", HOST: "0.0.0.0", OLLAMA_URL: "http://127.0.0.1:11434" }
    },
    {
      name: "relay",
      script: "./src/relay/index.js",
      cwd: "C:\RUNEFORGE_V2_CORE",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      watch: false,
      max_restarts: 10,
      min_uptime: "5s",
      env: { PORT: 3198, NODE_ENV: "production" }
    }
  ]
};
