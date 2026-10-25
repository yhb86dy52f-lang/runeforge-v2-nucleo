// telemetry.js - API de telemetría para RUNEFORGE
const os = require('os');

async function registerTelemetryRoutes(app) {
    // Endpoint básico de salud
    app.get('/api/health', async () => ({ ok: true, service: 'runeforge', ts: new Date().toISOString() }));

    // Endpoint de telemetría completa
    app.get('/api/telemetry', async () => {
        const cpus = os.cpus();
        const totalMem = os.totalmem();
        const freeMem = os.freemem();
        const usedMem = totalMem - freeMem;
        
        // Calcular carga de CPU
        let totalIdle = 0, totalTick = 0;
        cpus.forEach(cpu => {
            for (let type in cpu.times) {
                totalTick += cpu.times[type];
            }
            totalIdle += cpu.times.idle;
        });
        const cpuUsage = 100 - Math.round((totalIdle / totalTick) * 100);

        return {
            timestamp: new Date().toISOString(),
            cpu: {
                cores: cpus.length,
                model: cpus[0]?.model || 'Unknown',
                usage_percent: cpuUsage
            },
            memory: {
                total_gb: (totalMem / 1024 / 1024 / 1024).toFixed(2),
                used_gb: (usedMem / 1024 / 1024 / 1024).toFixed(2),
                free_gb: (freeMem / 1024 / 1024 / 1024).toFixed(2),
                usage_percent: Math.round((usedMem / totalMem) * 100)
            },
            uptime_seconds: os.uptime(),
            platform: os.platform(),
            hostname: os.hostname()
        };
    });

    app.log.info('Telemetry routes registered');
}

module.exports = { registerTelemetryRoutes };