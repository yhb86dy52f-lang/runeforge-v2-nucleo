const fs = require('fs');
const path = require('path');

const VAULT_PATH = 'C:\\RUNEFORGE_V2_CORE\\knowledge\\vault';

function createDailyNote(content) {
    const dateStr = new Date().toISOString().split('T')[0];
    const filePath = path.join(VAULT_PATH, '01_Diario', `${dateStr}.md`);
    const timeStr = new Date().toLocaleTimeString();
    const entry = `\n\n### [${timeStr}]\n${content}`;
    
    if (!fs.existsSync(filePath)) {
        const header = `# Bitácora del Día - ${dateStr}\n`;
        fs.writeFileSync(filePath, header + entry, 'utf8');
    } else {
        fs.appendFileSync(filePath, entry, 'utf8');
    }
    return { success: true, path: filePath };
}

module.exports = { createDailyNote };
