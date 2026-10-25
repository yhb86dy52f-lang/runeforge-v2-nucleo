const { ChromaClient } = require('chromadb');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const client = new ChromaClient({ path: "http://localhost:8000" });
const KNOWLEDGE_DIR = path.join(__dirname, '..', 'knowledge');

async function indexKnowledge() {
    try {
        const collection = await client.getOrCreateCollection({ embeddingFunction: null,
            name: "runeforge_knowledge",
            metadata: { "hnsw:space": "cosine" }
        });

        const files = fs.readdirSync(KNOWLEDGE_DIR, { recursive: true, withFileTypes: true });
        let processed = 0;

        for (const file of files) {
            if (file.isFile() && (file.name.endsWith('.md') || file.name.endsWith('.txt') || file.name.endsWith('.json'))) {
                const filePath = path.join(file.parentPath, file.name);
                const content = fs.readFileSync(filePath, 'utf-8');
                const chunks = content.match(/.{1,1000}(?:\s|$)/g) || [content];

                for (const chunk of chunks) {
                    try {
                        const resp = await axios.post('http://localhost:11434/api/embeddings', {
                            model: "nomic-embed-text",
                            prompt: chunk
                        });
                        const embedding = resp.data.embedding;

                        await collection.add({
                            ids: [`${file.name}_${Date.now()}_${Math.random()}`],
                            embeddings: [embedding],
                            metadatas: [{ source: file.name }],
                            documents: [chunk]
                        });
                        processed++;
                    } catch (err) {
                        console.error(`Error en chunk de ${file.name}:`, err.message);
                    }
                }
            }
        }
        console.log(`✅ Indexación completada. ${processed} chunks guardados en ChromaDB.`);
    } catch (err) {
        console.error("Error general:", err.message);
    }
}

indexKnowledge();

