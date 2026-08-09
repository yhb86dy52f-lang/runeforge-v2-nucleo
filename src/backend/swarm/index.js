import { StateGraph, START, END } from "@langchain/langgraph";
import { Ollama } from "@langchain/ollama";

const supervisor = new Ollama({ model: "qwen2.5:1.5b", baseUrl: "http://localhost:11434", temperature: 0.1 });
const coder = new Ollama({ model: "deepseek-coder", baseUrl: "http://localhost:11434", temperature: 0.1 });

const graphState = {
    messages: { value: (x, y) => x.concat(y), default: () => [] },
    task: { value: (x, y) => y, default: () => "" },
    code: { value: (x, y) => y, default: () => "" }
};

async function supervisorNode(state) {
    const response = await supervisor.invoke(`Analiza y divide esta tarea en lógica estricta. Tarea: ${state.task}`);
    return { messages: [`Supervisor: ${response}`] };
}

async function coderNode(state) {
    const response = await coder.invoke(`Escribe SOLO el código funcional basado en esto: ${state.task}. Ignora explicaciones.`);
    return { code: response, messages: ["Coder: Código generado."] };
}

const workflow = new StateGraph({ channels: graphState })
    .addNode("supervisor", supervisorNode)
    .addNode("coder", coderNode)
    .addEdge(START, "supervisor")
    .addEdge("supervisor", "coder")
    .addEdge("coder", END);

export const swarmApp = workflow.compile();

// Prueba de validación de módulo
if (process.argv[1].endsWith("index.js")) {
    (async () => {
        console.log("[RUNEFORGE SWARM] Ejecutando tarea de prueba...");
        const res = await swarmApp.invoke({ task: "Script Node.js para leer memoria RAM libre" });
        console.log(res.code);
    })();
}
