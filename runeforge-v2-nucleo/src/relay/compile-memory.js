const fs = require('fs');
const path = require('path');
const { OllamaEmbeddings } = require('@langchain/community/embeddings/ollama');

const KNOWLEDGE_DIR = path.join(__dirname, 'src', 'knowledge');
const DB_FILE = path.join(__dirname, 'vector_db.json');

const embedder = new OllamaEmbeddings({
    model: 'nomic-embed-text',
    baseUrl: 'http://localhost:11434'
});

async function compileMemory() {
    console.log('\n[🧠] Iniciando vectorización de conocimiento...');
    if (!fs.existsSync(KNOWLEDGE_DIR)) {
        console.log('[!] Directorio src/knowledge no encontrado.');
        return;
    }

    const files = fs.readdirSync(KNOWLEDGE_DIR).filter(f => f.endsWith('.md'));
    let db = [];

    for (const file of files) {
        console.log(`  [*] Procesando: ${file}`);
        const filePath = path.join(KNOWLEDGE_DIR, file);
        const text = fs.readFileSync(filePath, 'utf-8');
        const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 10);

        for (const chunk of lines) {
            try {
                const vector = await embedder.embedQuery(chunk);
                db.push({ source: file, text: chunk, vector });
            } catch (e) {
                console.log(`  [!] Error embed query en ${file}: ${e.message}`);
                db.push({ source: file, text: chunk, vector: [] });
            }
        }
    }

    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2));
    console.log(`[✅] Memoria compilada: ${db.length} nodos guardados en vector_db.json\n`);
}

compileMemory().catch(err => console.error('[❌] Error compilando memoria:', err));