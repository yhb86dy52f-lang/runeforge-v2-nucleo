module.exports = {
  apps: [
    { name: "runeforge-backend", script: "./server.js", cwd: "C:/RUNEFORGE_V2_CORE", instances: 1, exec_mode: "fork", env: { PORT: 3100, NODE_ENV: "production" } },
    { name: "relay", script: "./src/relay/index.js", cwd: "C:/RUNEFORGE_V2_CORE", instances: 1, exec_mode: "fork", env: { PORT: 3198 } }
  ]
}
