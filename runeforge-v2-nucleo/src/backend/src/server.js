const fastify = require('fastify')({ logger: false });
const path = require('path');

// Módulos Core
const { setupAIRoutes } = require('./ai-controller');

// Configuración de Servidor
const PORT = 3100;
const HOST = '0.0.0.0'; // Permite acceso desde Tailscale y la red local

// ================================================
// [RUNEFORGE PATCH] RUTAS PWA Y ARCHIVOS ESTÁTICOS
// ================================================
const fs = require('fs');

// 1. Servir archivos estáticos (sw.js, manifest.json, imágenes) desde la raíz real del proyecto
fastify.register(require('@fastify/static'), {
    // NOTA: Apuntamos directamente a la carpeta public de la raíz de C:\RUNEFORGE_V2_CORE
    root: 'C:\\RUNEFORGE_V2_CORE\\public', 
    prefix: '/pwa_assets/', // Se accede a ellos en localhost:3100/pwa_assets/sw.js
});

// 2. Ruta dedicada para la PWA (NO secuestra la raíz /)
fastify.get('/pwa', async (request, reply) => {
    const filePath = path.join('C:\\RUNEFORGE_V2_CORE\\public', 'index.html');
    if (fs.existsSync(filePath)) {
        reply.header('Content-Type', 'text/html');
        return reply.send(fs.readFileSync(filePath, 'utf8'));
    }
    return reply.status(500).send('Error: No se encontró index.html en C:\\RUNEFORGE_V2_CORE\\public');
});

// 3. Rutas auxiliares para que el navegador cargue el service worker y el manifiesto
fastify.get('/sw.js', async (req, reply) => {
    return reply.sendFile('sw.js');
});
fastify.get('/manifest.json', async (req, reply) => {
    return reply.sendFile('manifest.json');
});
// ================================================

// Endpoint de salud y comandos del sistema
fastify.get('/health', async () => { 
    return { ok: true, timestamp: new Date().toISOString(), mode: "ZERO_TERMINAL" } 
});

// Inyección de Rutas de IA y Comandos (WebCommand)
setupAIRoutes(fastify);

const start = async () => {
    try {
        await fastify.listen({ port: PORT, host: HOST });
        console.log(`[RUNEFORGE-CORE] SOBERANÍA ACTIVA EN http://${HOST}:${PORT}`);
        console.log(`[RUNEFORGE-PWA] Interfaz Offline disponible en: http://${HOST}:${PORT}/pwa`);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};
start();