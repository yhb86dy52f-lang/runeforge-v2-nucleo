const path = require('path');
module.exports = async function (fastify) {
  // Sirve /frontend como raiz
  const frontendPath = path.join(__dirname, '../../frontend');
  fastify.get('/forge', async (req, reply) => reply.sendFile('acceso-offline-moderada.html', frontendPath));
  fastify.get('/acceso-offline-moderada.html', async (req, reply) => reply.sendFile('acceso-offline-moderada.html', frontendPath));
  fastify.get('/acceso-multi.html', async (req, reply) => reply.sendFile('acceso-multi.html', frontendPath));
  fastify.get('/js/:file', async (req, reply) => reply.sendFile('js/'+req.params.file, frontendPath));

  fastify.get('/api/network', async () => {
    const os = require('os');
    const nets = os.networkInterfaces();
    const all = [];
    for (const k of Object.keys(nets)) for (const n of nets[k]) if(n.family==='IPv4'&&!n.internal) all.push({iface:k, ip:n.address});
    return { ok:true, local:'192.168.100.12', tailscale:'100.111.32.10', all, forge_local:'http://192.168.100.12:3100/forge', forge_tailscale:'http://100.111.32.10:3100/forge' };
  });
}
