// bitacora_parser.js - Parseo robusto Etapa 1 v2
// Regla: T_telemetria, P_problema, A_actividad, H_habito, R_tarea
// Si confidence baja -> responder "No entendi, es T/P/H/A/R? Ej: 'P Ciner sensor km 42 fallo'"

const crypto = require('crypto');

function parseBitacora(rawText){
  const texto_original = String(rawText||'').trim();
  if(!texto_original) return { tipo:'U', parse_confidence:'baja', texto_limpio:'', proyecto:'personal', estado:'duda', duda:true };

  // Normaliza
  const upper = texto_original.toUpperCase();
  const match = texto_original.match(/^\s*([TPAHR])\s+([\s\S]+)/i);
  let tipo = 'U';
  let resto = texto_original;
  let confidence = 'baja';

  if(match){
    tipo = match[1].toUpperCase();
    resto = match[2].trim();
    confidence = 'alta';
    // Si tiene proyecto explicito al inicio del resto
    // Ej: "P Ciner sensor fallo" -> proyecto Ciner
  } else if(/^[TPAHR]/i.test(texto_original)){
    // Solo letra sin texto
    tipo = upper[0];
    resto = texto_original.slice(1).trim();
    confidence = 'media';
  } else {
    // Intento heuristico por palabras clave
    if(/sensor|km|telemetria|ciner|falla|bloqueo/i.test(texto_original)){ tipo='T'; confidence='media'; }
    else if(/habito|rutina|gym|leer|dormir/i.test(texto_original)){ tipo='H'; confidence='media'; }
    else { tipo='U'; confidence='baja'; }
  }

  // Proyecto
  let proyecto = 'personal';
  const projMatch = resto.match(/^(Ciner|Runeforge|Personal)\s+/i);
  if(projMatch){
    proyecto = projMatch[1].toLowerCase() === 'ciner' ? 'Ciner' : projMatch[1].toLowerCase();
    resto = resto.slice(projMatch[0].length).trim();
    if(confidence==='media') confidence='alta';
  } else if(tipo==='T'){
    proyecto='Ciner'; // telemetria por defecto es trabajo
  }

  const texto_limpio = resto;
  const hash = crypto.createHash('sha256').update((new Date().toISOString().slice(0,10) + '|' + texto_original).toLowerCase()).digest('hex').slice(0,16);
  const duda = confidence==='baja' || tipo==='U';

  return {
    fecha: new Date().toISOString(),
    tipo,
    proyecto,
    texto_original,
    texto_limpio,
    estado: duda ? 'duda' : 'pendiente',
    origen: 'manual',
    parse_confidence: confidence,
    hash,
    duda,
    respuesta: duda ? `No entendi, ¿es T/P/H/A/R? Ej: 'P Ciner sensor km 42 fallo'. Tu texto: "${texto_original.slice(0,80)}"` : null
  };
}

module.exports = { parseBitacora };
