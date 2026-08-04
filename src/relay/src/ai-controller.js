const { Ollama } = require('@langchain/community/llms/ollama');
const { PromptTemplate } = require('@langchain/core/prompts');
const { retrieveContext } = require('./rag-system');

const localAI = new Ollama({
  baseUrl: 'http://localhost:11434',
  model: 'deepseek-coder',
  temperature: 0.1,
});

const CINER_SYSTEM_PROMPT = `Eres CINER / Tinkerbell, Copiloto de Ingeniería Senior especializado en Telemetría GPS, IoT, Metrología, Sensores Escort TD-500/600 y Wialon.
Trabajas codo a codo como colega técnico del Ing. Néstor ("Tinkerbell").

ESTÁ PROHIBIDO responder que eres un asistente genérico o limitado a programación.
ERES UN EXPERTO EN METROLOGÍA, SENSORES Y TELEMETRÍA AUTOMOTRIZ.

BASE DE CONOCIMIENTO RAG RECUPERADA DE DISCO:
{context}

REGLAS STRICTAS:
1. Utiliza el CONOCIMIENTO RAG de arriba para responder con exactitud matemática.
2. Si la consulta es sobre Wialon/Escort: Especifica el algoritmo PCHIP (Spline Cúbico Monotónico), 100 puntos y el error máximo tolerable de 0.08L en extremos.
3. Sé directo, técnico y conciso.

Consulta del Ing. Néstor: {input}
Respuesta técnica de CINER:`;

const promptTemplate = PromptTemplate.fromTemplate(CINER_SYSTEM_PROMPT);

async function setupAIRoutes(fastify) {
  fastify.post('/api/ai/chat', async (request, reply) => {
    try {
      const { message } = request.body;
      const ragContext = await retrieveContext(message);
      
      console.log(`[RUNEFORGE-AI] Consulta: "${message.substring(0, 40)}..." | Contexto RAG: ${ragContext.length} chars`);

      const formattedPrompt = await promptTemplate.format({
        context: ragContext || "Algoritmo recomendado: PCHIP (Spline Cúbico Monotónico). Puntos: 100. Error máximo extremos: 0.08L.",
        input: message
      });

      const response = await localAI.invoke(formattedPrompt);

      return reply.send({
        status: 'success',
        timestamp: new Date().toISOString(),
        agent: 'Tinkerbell-V4.4',
        response: response
      });
    } catch (error) {
      console.error('[RUNEFORGE-AI] Error:', error.message);
      return reply.status(500).send({ error: 'Falla en el enlace local con Ollama.' });
    }
  });
}

module.exports = { setupAIRoutes };