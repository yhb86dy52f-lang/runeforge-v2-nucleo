module.exports = {
  apps: [
    { 
      name: "runeforge-backend", 
      script: "./server.js", 
      cwd: "C:/RUNEFORGE_V2_CORE", 
      instances: 1, 
      exec_mode: "fork", 
      env: { PORT: 3001, NODE_ENV: "production" } 
    }
  ]
}
