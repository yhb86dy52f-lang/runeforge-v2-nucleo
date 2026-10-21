<script>
  import { onMount, onDestroy } from 'svelte';

  let canvas;
  let ctx;
  let animationFrame;
  let fetchInterval;
  
  let ecosystem = { nodes: [] };
  let health = { core: { cpu_percent: 0, ram_percent: 0 }, hardware: {} };
  let angles = {};
  
  onMount(() => {
    ctx = canvas.getContext('2d');
    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    async function fetchData() {
      try {
        // 1. Leer Nodos (Servicios)
        const resNodes = await fetch('/ecosystem.json');
        if (resNodes.ok) {
          const dataNodes = await resNodes.json();
          dataNodes.nodes.forEach((node) => {
            if (!angles[node.id]) angles[node.id] = Math.random() * Math.PI * 2;
          });
          ecosystem = dataNodes;
        }

        // 2. Leer Hardware (Telemetría)
        const resHealth = await fetch('/system_health.json');
        if (resHealth.ok) {
          health = await resHealth.json();
        }
      } catch (error) {
        console.warn("Esperando datos del sistema...");
      }
    }

    fetchData();
    fetchInterval = setInterval(fetchData, 2000);

    draw();
  });

  onDestroy(() => {
    window.removeEventListener('resize', resizeCanvas);
    cancelAnimationFrame(animationFrame);
    clearInterval(fetchInterval);
  });

  function resizeCanvas() {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
  }

  function draw() {
    const width = canvas.width;
    const height = canvas.height;
    const centerX = width / 2;
    const centerY = height / 2;

    ctx.fillStyle = '#0a0a10';
    ctx.fillRect(0, 0, width, height);

    // 1. NÚCLEO DINÁMICO (Basado en Uso de CPU)
    const cpuLoad = health.core.cpu_percent || 0;
    const coreRadius = 40 + (cpuLoad * 0.4); // El núcleo crece con la CPU

    ctx.beginPath();
    ctx.arc(centerX, centerY, coreRadius, 0, Math.PI * 2);
    ctx.fillStyle = cpuLoad > 80 ? 'rgba(255, 0, 0, 0.3)' : 'rgba(255, 165, 0, 0.2)'; 
    ctx.fill();
    ctx.lineWidth = 3;
    ctx.strokeStyle = cpuLoad > 80 ? '#ff0000' : '#ff8c00';
    ctx.stroke();

    // Texto del Núcleo
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 14px monospace';
    ctx.textAlign = 'center';
    ctx.fillText(`CORE`, centerX, centerY - 5);
    ctx.font = '12px monospace';
    ctx.fillStyle = '#ff8c00';
    ctx.fillText(`CPU: ${cpuLoad}% | RAM: ${health.core.ram_percent || 0}%`, centerX, centerY + 15);

    // Información de Hardware (Esquina inferior izquierda)
    if (health.hardware && health.hardware.GPU_Name) {
      ctx.textAlign = 'left';
      ctx.fillStyle = '#888';
      ctx.font = '12px monospace';
      ctx.fillText(`GPU: ${health.hardware.GPU_Name}`, 20, height - 40);
      ctx.fillText(`Disk: ${health.hardware.Disk_Type}`, 20, height - 20);
    }

    // 2. NODOS Y SINAPSIS
    ecosystem.nodes.forEach((node) => {
      const angle = angles[node.id] || 0;
      const distance = 250; 
      const x = centerX + Math.cos(angle) * distance;
      const y = centerY + Math.sin(angle) * distance;

      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.lineTo(x, y);
      ctx.lineWidth = node.status === 'online' ? 2 : 1;
      ctx.strokeStyle = node.status === 'online' ? 'rgba(0, 255, 255, 0.5)' : 'rgba(100, 100, 100, 0.2)';
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(x, y, 20, 0, Math.PI * 2);
      ctx.fillStyle = node.status === 'online' ? 'rgba(0, 255, 255, 0.2)' : 'rgba(255, 0, 0, 0.1)';
      ctx.fill();
      ctx.lineWidth = 2;
      ctx.strokeStyle = node.status === 'online' ? '#00ffff' : '#550000';
      ctx.stroke();

      ctx.fillStyle = node.status === 'online' ? '#00ffff' : '#888';
      ctx.font = '12px monospace';
      ctx.textAlign = 'center';
      ctx.fillText(node.id, x, y + 40);
      ctx.font = '10px monospace';
      ctx.fillText(`Puerto: ${node.port}`, x, y + 55);
    });

    for (let key in angles) { angles[key] += 0.002; }
    animationFrame = requestAnimationFrame(draw);
  }
</script>

<main>
  <canvas bind:this={canvas}></canvas>
</main>

<style>
  :global(body) { margin: 0; padding: 0; overflow: hidden; background-color: #0a0a10; font-family: 'Courier New', Courier, monospace; }
  main { width: 100vw; height: 100vh; }
</style>