// test_parser.js - Prueba rapida del parser T/P/A/H/R
const { parseBitacora } = require('./services/bitacora_parser.js');
const tests = [
  'P Ciner sensor km 42 fallo',
  'T Ciner km 88 temperatura alta',
  'H gym 45 min',
  'A Runeforge configure Obsidian clipper',
  'R comprar refacciones',
  'sensor fallo sin prefijo'
];
tests.forEach(t=>{
  const p = parseBitacora(t);
  console.log(`[${p.tipo}/${p.proyecto}] conf=${p.parse_confidence} duda=${p.duda} -> "${p.texto_limpio}" ${p.respuesta||''}`);
});
