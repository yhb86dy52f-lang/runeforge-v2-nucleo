const { parseBitacora } = require('./services/bitacora_parser.js');
['P Ciner sensor km 42 fallo','T Ciner km 88 temp alta','H gym 45 min','A Runeforge obsidian'].forEach(t=>{
  const p=parseBitacora(t); console.log(`[${p.tipo}/${p.proyecto}] ${p.texto_limpio} conf=${p.parse_confidence}`);
});
