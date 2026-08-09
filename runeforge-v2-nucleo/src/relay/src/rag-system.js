const fs = require('fs');
const path = require('path');
const { OllamaEmbeddings } = require('@langchain/community/embeddings/ollama');

const DB_FILE = path.join(__dirname, '..', 'vector_db.json');

const embedder = new OllamaEmbeddings({
    model: 'nomic-embed-text',
    baseUrl: 'http://localhost:11434'
});

function cosineSimilarity(a, b) {
    if (!a || !b || a.length !== b.length || a.length === 0) return 0;
    let dot = 0, normA = 0, normB = 0;
    for (let i = 0; i < a.length; i++) {
        dot += a[i] * b[i];
        normA += a[i] * a[i];
        normB += b[i] * b[i];
    }
    return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

async function retrieveContext(query) {
    if (!fs.existsSync(DB_FILE)) {
        console.log('[RAG] Warning: vector_db.json no existe aún.');
        return '';
    }

    try {
        const rawData = fs.readFileSync(DB_FILE, 'utf-8');
        const db = JSON.parse(rawData);
        if (!Array.isArray(db) || db.length === 0) return '';

        let queryVector = [];
        try {
            queryVector = await embedder.embedQuery(query);
        } catch (e) {
            console.log('[RAG] Fallback a búsqueda semántica por palabras clave.');
        }

        let scored = db.map(item => {
            let score = 0;
            if (queryVector.length > 0 && item.vector && item.vector.length > 0) {
                score = cosineSimilarity(queryVector, item.vector);
            } else {
                const words = query.toLowerCase().split(/\s+/).filter(w => w.length > 3);
                const itemText = item.text.toLowerCase();
                words.forEach(w => { if (itemText.includes(w)) score += 0.2; });
            }
            return { text: item.text, score };
        });

        scored.sort((a, b) => b.score - a.score);
        const topChunks = scored.slice(0, 5).map(s => s.text);
        return topChunks.join('\n');
    } catch (err) {
        console.error('[RAG] Error recuperando contexto:', err.message);
        return '';
    }
}

module.exports = { retrieveContext };