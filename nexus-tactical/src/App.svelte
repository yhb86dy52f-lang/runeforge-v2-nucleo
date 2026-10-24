<script>
  import { invoke } from '@tauri-apps/api/core';
  import './app.css';
  let rawInput = '';
  let parsedOutput = '';
  let isExecuting = false;

  async function executeCommand(commandStr) {
    if (!commandStr) return;
    isExecuting = true;
    parsedOutput = '[SISTEMA] Ejecutando comando en el núcleo...';
    try {
      const result = await invoke('execute_local_command', { command: commandStr });
      parsedOutput = result || '[SISTEMA] Comando ejecutado sin salida.';
    } catch (error) {
      parsedOutput = `[ERROR] Fallo de ejecución: ${error}`;
    } finally {
      isExecuting = false;
    }
  }

  function processPayload() { executeCommand(rawInput); }
  
  function auditSystem() {
    const auditCmd = 'Get-CimInstance Win32_Processor | Select-Object -ExpandProperty LoadPercentage';
    rawInput = auditCmd;
    executeCommand(auditCmd);
  }

  function startWhisper() {
    // Comando para encender el backend de Python en una ventana minimizada
    const whisperCmd = 'Start-Process -FilePath "C:\\RUNEFORGE_V2_CORE\\whisper-backend\\venv\\Scripts\\python.exe" -ArgumentList "server.py" -WorkingDirectory "C:\\RUNEFORGE_V2_CORE\\whisper-backend" -WindowStyle Minimized';
    rawInput = whisperCmd;
    executeCommand(whisperCmd);
  }
</script>

<main style="padding: 24px; max-width: 900px; margin: 0 auto;">
  <header style="margin-bottom: 24px; border-bottom: 1px solid var(--border-neon); padding-bottom: 12px;">
    <h1 style="color: var(--neon-green); font-size: 20px; text-shadow: 0 0 8px rgba(57,255,20,0.5);">RUNEFORGE // NUCLEO TÁCTICO V2</h1>
    <p style="font-size: 12px; opacity: 0.8;">Soberanía Local &bull; Estado: <span style="color: {isExecuting ? '#FFA500' : 'var(--neon-green)'};">{isExecuting ? 'OCUPADO' : 'ACTIVO'}</span></p>
  </header>

  <div class="glass-panel" style="padding: 16px; margin-bottom: 16px;">
    <label for="cmdInput" style="display: block; font-size: 12px; color: var(--neon-green); margin-bottom: 8px;">ENTRADA DE COMANDOS (POWERSHELL)</label>
    <textarea 
      id="cmdInput"
      bind:value={rawInput} 
      disabled={isExecuting} 
      placeholder="Introduce un comando de PowerShell aquí..." 
      style="width: 100%; height: 100px; background: #050108; color: var(--neon-green); border: 1px solid var(--border-neon); padding: 8px; font-family: monospace; border-radius: 4px;"
    ></textarea>
    
    <div style="display: flex; gap: 12px; margin-top: 12px; flex-wrap: wrap;">
      <button on:click={processPayload} disabled={isExecuting} style="background: transparent; color: var(--neon-green); border: 1px solid var(--neon-green); padding: 8px 16px; cursor: pointer; border-radius: 4px; font-weight: bold;">
        {isExecuting ? 'EJECUTANDO...' : 'EJECUTAR COMANDO'}
      </button>
      
      <button on:click={auditSystem} disabled={isExecuting} style="background: var(--neon-green); color: #0D0211; border: 1px solid var(--neon-green); padding: 8px 16px; cursor: pointer; border-radius: 4px; font-weight: bold; box-shadow: 0 0 10px rgba(57,255,20,0.4);">
        AUDITAR SISTEMA (CPU)
      </button>

      <button on:click={startWhisper} disabled={isExecuting} style="background: #8A2BE2; color: white; border: 1px solid #8A2BE2; padding: 8px 16px; cursor: pointer; border-radius: 4px; font-weight: bold; box-shadow: 0 0 10px rgba(138,43,226,0.4);">
        ARRANCAR WHISPER (GPU)
      </button>
    </div>
  </div>

  <div class="glass-panel" style="padding: 16px;">
    <h3 style="font-size: 14px; color: var(--neon-green); margin-top: 0;">SALIDA DEL SISTEMA</h3>
    <pre style="background: #050108; padding: 12px; border: 1px dashed var(--border-neon); color: #fff; font-size: 12px; min-height: 50px; white-space: pre-wrap; word-wrap: break-word;">{parsedOutput || 'Esperando flujo de datos...'}</pre>
  </div>
</main>