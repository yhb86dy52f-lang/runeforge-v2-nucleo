const store = require('./botforce.store');

function classify(text) {
  const raw = String(text || '');
  const s = raw.toLowerCase();

  if (!raw.trim()) {
    return {
      type: 'empty',
      priority: 'low',
      tags: ['botforce', 'empty']
    };
  }

  const rules = [
    { type: 'legal_ops', priority: 'high', tags: ['juridico', 'evidencia'], words: ['demanda', 'denuncia', 'abogado', 'contrato', 'legal', 'juridico', 'acta', 'prueba', 'evidencia'] },
    { type: 'incident_report', priority: 'high', tags: ['incidente', 'seguridad'], words: ['incidente', 'robo', 'daño', 'alarma', 'intrusion', 'intrusión', 'sabotaje', 'falla'] },
    { type: 'technical_log', priority: 'normal', tags: ['tecnico', 'bitacora'], words: ['cctv', 'dvr', 'nvr', 'gps', 'calamp', 'wialon', 'traccar', 'sensor', 'power', 'voltaje', 'puerto'] },
    { type: 'task_request', priority: 'normal', tags: ['tarea'], words: ['hacer', 'crear', 'revisar', 'validar', 'pendiente', 'seguimiento'] }
  ];

  for (const rule of rules) {
    if (rule.words.some((w) => s.includes(w))) {
      return {
        type: rule.type,
        priority: rule.priority,
        tags: ['botforce', ...rule.tags]
      };
    }
  }

  return {
    type: 'general_note',
    priority: 'normal',
    tags: ['botforce', 'general']
  };
}

function buildMarkdown(input, classification, traceId) {
  const ts = new Date().toISOString();
  const text = String(input.text || '');
  const source = input.source || 'api';
  const title = input.title || `Botforce ${classification.type}`;

  return [
    `# ${title}`,
    '',
    `ts: ${ts}`,
    `source: ${source}`,
    `traceId: ${traceId}`,
    `type: ${classification.type}`,
    `priority: ${classification.priority}`,
    `tags: ${classification.tags.join(', ')}`,
    '',
    '## Entrada',
    '',
    text || '_Sin texto_',
    '',
    '## Lectura operativa',
    '',
    `- Clasificación: ${classification.type}`,
    `- Prioridad: ${classification.priority}`,
    '- Nota: apoyo documental/operativo; no sustituye revisión profesional legal.',
    '',
    '## Siguiente acción sugerida',
    '',
    '- Validar hechos, fechas, actores, evidencia y fuente original antes de usar el reporte.'
  ].join('\n');
}

function ingest(payload) {
  const input = {
    text: payload && payload.text ? String(payload.text) : '',
    title: payload && payload.title ? String(payload.title) : '',
    source: payload && payload.source ? String(payload.source) : 'api',
    meta: payload && payload.meta ? payload.meta : {}
  };

  const classification = classify(input.text);
  const trace = store.writeJson('botforce_ingest', {
    input,
    classification,
    status: 'ingested'
  });

  const markdownBody = buildMarkdown(input, classification, trace.id);
  const note = store.writeMarkdown('botforce_note', input.title, markdownBody);

  return {
    ok: true,
    id: trace.id,
    classification,
    traceFile: trace.file,
    noteFile: note.file
  };
}

function health() {
  store.ensureDirs();
  return {
    ok: true,
    service: 'botforce',
    mode: 'local-first',
    dirs: store.dirs
  };
}

function latest() {
  return store.latestTrace();
}

module.exports = {
  ingest,
  health,
  latest
};
