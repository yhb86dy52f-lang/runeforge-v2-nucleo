import { Ollama } from "@langchain/ollama";

const supervisor = new Ollama({ model: "qwen2.5:1.5b", baseUrl: "http://localhost:11434", temperature: 0.1 });
const coder = new Ollama({ model: "deepseek-coder", baseUrl: "http://localhost:11434", temperature: 0.1 });

(async () => {
    try {
        console.log("\n[1/4] Iniciando prueba de Enjambre directo...");
        
        console.log("[2/4] Cargando Qwen2.5:1.5b en VRAM (Supervisor)...");
        const t1 = Date.now();
        const res1 = await supervisor.invoke("Responde 'OK' si me escuchas.");
        console.log(`      -> Qwen responde: ${res1.trim()} (Tardó: ${Date.now() - t1}ms)`);

        console.log("\n[3/4] Haciendo swapping a DeepSeek-Coder en VRAM (Coder)...");
        const t2 = Date.now();
        const res2 = await coder.invoke("Escribe 'print(OK)' en Python.");
        console.log(`      -> DeepSeek responde: ${res2.trim()} (Tardó: ${Date.now() - t2}ms)`);

        console.log("\n[4/4] PRUEBA SUPERADA. El Swapping funciona correctamente.");
    } catch (err) {
        console.error("\n[X] FALLO CRÍTICO EN OLLAMA:", err.message);
    }
})();
