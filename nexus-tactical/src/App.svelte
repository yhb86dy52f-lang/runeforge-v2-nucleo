<script>
  import { onMount } from 'svelte';

  let telemetry = {
    cpu: { usage_percent: 0, cores: 4, model: 'Cargando...' },
    memory: { used_gb: 0, total_gb: 16, usage_percent: 0 },
    hostname: 'Cargando...',
    uptime_seconds: 0
  };
  let isConnected = false;

  async function fetchTelemetry() {
    try {
      const res = await fetch('http://localhost:3100/api/telemetry');
      if (res.ok) {
        telemetry = await res.json();
        isConnected = true;
      } else {
        isConnected = false;
      }
    } catch (e) {
      console.error("Error fetching telemetry:", e);
      isConnected = false;
    }
  }

  onMount(() => {
    fetchTelemetry();
    const interval = setInterval(fetchTelemetry, 2000);
    return () => clearInterval(interval);
  });

  function formatUptime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return `${h}h ${m}m`;
  }
</script>

<main class="container">
  <header>
    <h1>⚡ RUNEFORGE TACTICAL</h1>
    <p class="status" class:online={isConnected} class:offline={!isConnected}>
      {isConnected ? '🟢 CONECTADO A FASTIFY' : '🔴 DESCONECTADO'}
    </p>
  </header>

  <div class="grid">
    <div class="card">
      <h2>PROCESADOR</h2>
      <div class="value">{telemetry.cpu.usage_percent}%</div>
      <div class="bar-container">
        <div class="bar cpu-bar" style="width: {telemetry.cpu.usage_percent}%"></div>
      </div>
      <p class="detail">{telemetry.cpu.cores} Núcleos</p>
    </div>

    <div class="card">
      <h2>MEMORIA RAM</h2>
      <div class="value">{telemetry.memory.usage_percent}%</div>
      <div class="bar-container">
        <div class="bar ram-bar" style="width: {telemetry.memory.usage_percent}%"></div>
      </div>
      <p class="detail">{telemetry.memory.used_gb} GB / {telemetry.memory.total_gb} GB</p>
    </div>

    <div class="card wide">
      <h2>ESTADO DEL NODO</h2>
      <div class="info-row">
        <span>Host:</span> <strong>{telemetry.hostname}</strong>
      </div>
      <div class="info-row">
        <span>Uptime:</span> <strong>{formatUptime(telemetry.uptime_seconds)}</strong>
      </div>
    </div>
  </div>
</main>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    background-color: #0D0211;
    color: #D0D0E0;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
  }

  .container {
    width: 100%;
    max-width: 800px;
    padding: 2rem;
    box-sizing: border-box;
  }

  header {
    text-align: center;
    margin-bottom: 3rem;
  }

  h1 {
    color: #39FF14;
    font-size: 2.5rem;
    text-shadow: 0 0 10px rgba(57, 255, 20, 0.5);
    margin-bottom: 0.5rem;
  }

  .status {
    font-weight: bold;
    font-size: 1.1rem;
    transition: color 0.3s ease;
  }

  .status.online { color: #39FF14; }
  .status.offline { color: #FF0055; }

  .grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.5rem;
  }

  .card {
    background: #1A0B1F;
    border: 1px solid rgba(57, 255, 20, 0.2);
    border-radius: 8px;
    padding: 1.5rem;
    text-align: center;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.5);
    transition: transform 0.2s;
  }

  .card:hover {
    transform: translateY(-5px);
    border-color: #39FF14;
    box-shadow: 0 4px 20px rgba(57, 255, 20, 0.2);
  }

  .card.wide {
    grid-column: span 2;
    text-align: left;
  }

  h2 {
    color: #00F0FF;
    font-size: 1rem;
    letter-spacing: 2px;
    margin-top: 0;
    margin-bottom: 1rem;
    border-bottom: 1px solid rgba(0, 240, 255, 0.2);
    padding-bottom: 0.5rem;
  }

  .value {
    font-size: 3rem;
    font-weight: bold;
    color: #39FF14;
    margin-bottom: 1rem;
  }

  .bar-container {
    width: 100%;
    height: 12px;
    background: #080A12;
    border-radius: 6px;
    overflow: hidden;
    margin-bottom: 1rem;
    border: 1px solid rgba(57, 255, 20, 0.3);
  }

  .bar {
    height: 100%;
    transition: width 0.5s ease-out;
  }

  .cpu-bar { background: #00F0FF; box-shadow: 0 0 10px #00F0FF; }
  .ram-bar { background: #39FF14; box-shadow: 0 0 10px #39FF14; }

  .detail {
    margin: 0;
    color: #888;
    font-size: 0.9rem;
  }

  .info-row {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem 0;
    border-bottom: 1px dashed rgba(255,255,255,0.1);
  }

  .info-row strong {
    color: #39FF14;
  }
</style>