import React, { useMemo, useState } from 'react';

const MODULES = [
  { id: 'general', label: 'General', hint: 'Orquestación base' },
  { id: 'telemetria', label: 'Telemetría', hint: 'GPS / CalAmp / diagnóstico' },
  { id: 'cctv', label: 'CCTV', hint: 'Cámaras / DVR / evidencia' },
  { id: 'incidencias', label: 'Incidencias', hint: 'Tickets / seguimiento' },
  { id: 'bitacora', label: 'Bitácora', hint: 'Notas / historial' },
  { id: 'system', label: 'Sistema', hint: 'Health / status / trace' },
];

const QUICK_ACTIONS = [
  { label: 'Revisar health', message: 'estado del sistema', module: 'system' },
  { label: 'Leer APN', message: 'leer apn', module: 'telemetria' },
  { label: 'Consultar inbound IP', message: 'leer inbound ip', module: 'telemetria' },
  { label: 'Consultar inbound port', message: 'leer inbound port', module: 'telemetria' },
];

function buildSessionId() {
  return `forge-session-${Date.now()}`;
}

function cx(...classes) {
  return classes.filter(Boolean).join(' ');
}

function renderBlock(block, index) {
  if (!block || typeof block !== 'object') return null;

  if (block.type === 'header') {
    return (
      <div key={index} className="text-sm font-semibold text-zinc-100">
        {block.text}
      </div>
    );
  }

  if (block.type === 'text') {
    return (
      <div key={index} className="rounded-xl border border-zinc-800 bg-zinc-900/60 p-3 text-sm leading-6 text-zinc-300">
        {block.text}
      </div>
    );
  }

  if (block.type === 'kv' && Array.isArray(block.items)) {
    return (
      <div key={index} className="grid grid-cols-1 gap-2 sm:grid-cols-2">
        {block.items.map((item, itemIndex) => (
          <div key={`${index}-${itemIndex}`} className="rounded-xl border border-zinc-800 bg-zinc-900/60 p-3">
            <div className="text-[11px] uppercase tracking-[0.2em] text-zinc-500">{item.key}</div>
            <div className="mt-1 text-sm font-medium text-zinc-200 break-all">{String(item.value ?? '')}</div>
          </div>
        ))}
      </div>
    );
  }

  if (block.type === 'list' && Array.isArray(block.items)) {
    return (
      <div key={index} className="rounded-xl border border-zinc-800 bg-zinc-900/60 p-3">
        <div className="text-xs uppercase tracking-[0.2em] text-zinc-500">{block.title || 'Lista'}</div>
        <ul className="mt-2 space-y-2 text-sm text-zinc-300">
          {block.items.map((item, itemIndex) => (
            <li key={`${index}-${itemIndex}`} className="rounded-lg border border-zinc-800 bg-zinc-950/70 px-3 py-2">
              {String(item)}
            </li>
          ))}
        </ul>
      </div>
    );
  }

  if (block.type === 'action') {
    return (
      <div key={index} className="rounded-xl border border-zinc-800 bg-zinc-900/60 p-3">
        <div className="text-xs uppercase tracking-[0.2em] text-zinc-500">Acción</div>
        <div className="mt-2 grid grid-cols-1 gap-2 text-sm text-zinc-300 sm:grid-cols-3">
          <div className="rounded-lg border border-zinc-800 bg-zinc-950/70 px-3 py-2">
            <div className="text-[11px] uppercase tracking-[0.2em] text-zinc-500">action</div>
            <div className="mt-1 break-all">{block.action || 'N/A'}</div>
          </div>
          <div className="rounded-lg border border-zinc-800 bg-zinc-950/70 px-3 py-2">
            <div className="text-[11px] uppercase tracking-[0.2em] text-zinc-500">status</div>
            <div className="mt-1 break-all">{block.status || 'N/A'}</div>
          </div>
          <div className="rounded-lg border border-zinc-800 bg-zinc-950/70 px-3 py-2">
            <div className="text-[11px] uppercase tracking-[0.2em] text-zinc-500">result</div>
            <div className="mt-1 break-all">{block.result ? JSON.stringify(block.result) : 'null'}</div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <pre key={index} className="overflow-auto rounded-xl border border-zinc-800 bg-zinc-950/70 p-3 text-xs text-zinc-300">
      {JSON.stringify(block, null, 2)}
    </pre>
  );
}

export default function ForgeUiNexoV1Runeforge() {
  const [activeModule, setActiveModule] = useState('system');
  const [sessionId] = useState(buildSessionId);
  const [apiBase, setApiBase] = useState('http://localhost:3100');
  const [input, setInput] = useState('estado del sistema');
  const [messages, setMessages] = useState([
    {
      id: 'boot-1',
      role: 'assistant',
      title: 'Forge / Nexo v1',
      text: 'Consola conectada a backend real por POST /api/chat.',
      blocks: [
        {
          type: 'kv',
          items: [
            { key: 'Estado', value: 'ONLINE' },
            { key: 'Modo', value: 'MVP' },
            { key: 'Entorno', value: 'Privado / Tailscale' },
          ],
        },
      ],
      meta: { route: 'system', status: 'ready' },
    },
  ]);
  const [pending, setPending] = useState(false);
  const [lastReply, setLastReply] = useState(null);
  const [error, setError] = useState('');

  const activeModuleLabel = useMemo(() => {
    return MODULES.find((item) => item.id === activeModule)?.label || activeModule;
  }, [activeModule]);

  async function sendMessage(messageText, moduleOverride) {
    const finalMessage = String(messageText || '').trim();
    const finalModule = moduleOverride || activeModule;

    if (!finalMessage || pending) return;

    const userMessage = {
      id: `user-${Date.now()}`,
      role: 'user',
      text: finalMessage,
    };

    setMessages((prev) => [...prev, userMessage]);
    setPending(true);
    setError('');

    try {
      const response = await fetch(`${apiBase.replace(/\/$/, '')}/api/chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: finalMessage,
          module: finalModule,
          sessionId,
        }),
      });

      const data = await response.json();

      if (!response.ok || !data?.ok) {
        throw new Error(data?.error || `HTTP_${response.status}`);
      }

      setLastReply(data);
      setMessages((prev) => [
        ...prev,
        {
          id: `assistant-${Date.now()}`,
          role: 'assistant',
          title: `Ruta: ${data.route}`,
          text: data.reply?.text || 'Respuesta recibida.',
          blocks: Array.isArray(data.reply?.blocks) ? data.reply.blocks : [],
          meta: {
            route: data.route,
            sessionId: data.sessionId,
            allowedActions: data.reply?.allowedActions || [],
          },
        },
      ]);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'CHAT_REQUEST_FAILED';
      setError(message);
      setMessages((prev) => [
        ...prev,
        {
          id: `assistant-error-${Date.now()}`,
          role: 'assistant',
          title: 'Error operativo',
          text: `Falló la llamada a /api/chat: ${message}`,
          blocks: [],
          meta: { route: 'error' },
        },
      ]);
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 p-4 md:p-6">
      <div className="mx-auto max-w-7xl grid grid-cols-1 gap-4 lg:grid-cols-[260px_minmax(0,1fr)_320px]">
        <aside className="rounded-2xl border border-zinc-800 bg-zinc-900/70 p-4 shadow-2xl">
          <div className="mb-5">
            <div className="text-xs uppercase tracking-[0.3em] text-zinc-500">Runeforge</div>
            <h1 className="mt-2 text-2xl font-semibold">Forge / Nexo v1</h1>
            <p className="mt-2 text-sm text-zinc-400">Consola conversacional privada conectada a backend real.</p>
          </div>

          <div>
            <div className="mb-2 text-xs font-medium uppercase tracking-[0.2em] text-zinc-500">Módulos</div>
            <div className="space-y-2">
              {MODULES.map((module) => (
                <button
                  key={module.id}
                  onClick={() => setActiveModule(module.id)}
                  className={cx(
                    'w-full rounded-2xl border p-3 text-left transition',
                    activeModule === module.id
                      ? 'border-zinc-600 bg-zinc-800 shadow-lg'
                      : 'border-zinc-800 bg-zinc-900 hover:border-zinc-700 hover:bg-zinc-800/80'
                  )}
                >
                  <div className="text-sm font-semibold">{module.label}</div>
                  <div className="mt-1 text-xs text-zinc-400">{module.hint}</div>
                </button>
              ))}
            </div>
          </div>

          <div className="mt-6 rounded-2xl border border-zinc-800 bg-zinc-950/60 p-3">
            <div className="text-xs uppercase tracking-[0.2em] text-zinc-500">Quick actions</div>
            <div className="mt-3 flex flex-wrap gap-2">
              {QUICK_ACTIONS.map((action) => (
                <button
                  key={action.label}
                  onClick={() => {
                    setActiveModule(action.module);
                    setInput(action.message);
                    void sendMessage(action.message, action.module);
                  }}
                  className="rounded-full border border-zinc-700 px-3 py-1 text-xs text-zinc-300 hover:bg-zinc-800"
                >
                  {action.label}
                </button>
              ))}
            </div>
          </div>
        </aside>

        <main className="rounded-2xl border border-zinc-800 bg-zinc-900/70 shadow-2xl">
          <div className="border-b border-zinc-800 px-4 py-4 md:px-5">
            <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
              <div>
                <div className="text-xs uppercase tracking-[0.25em] text-zinc-500">Sesión</div>
                <div className="mt-1 text-lg font-semibold">{sessionId}</div>
              </div>
              <div className="flex flex-wrap gap-2 text-xs">
                <span className="rounded-full border border-emerald-700/50 bg-emerald-900/30 px-3 py-1 text-emerald-300">
                  {pending ? 'Consultando backend…' : 'Backend disponible'}
                </span>
                <span className="rounded-full border border-zinc-700 px-3 py-1 text-zinc-300">Módulo: {activeModuleLabel}</span>
                <span className="rounded-full border border-zinc-700 px-3 py-1 text-zinc-300">Base: {apiBase}</span>
              </div>
            </div>
          </div>

          <div className="space-y-4 p-4 md:p-5 max-h-[70vh] overflow-auto">
            {messages.map((message) => (
              <div key={message.id} className={`flex ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div className={cx(
                  'max-w-3xl rounded-2xl border p-4',
                  message.role === 'user'
                    ? 'border-zinc-700 bg-zinc-800'
                    : 'border-zinc-800 bg-zinc-950/70'
                )}>
                  {message.title ? <div className="mb-2 text-sm font-semibold text-zinc-100">{message.title}</div> : null}
                  <p className="text-sm leading-6 text-zinc-300 whitespace-pre-wrap">{message.text}</p>

                  {message.meta ? (
                    <div className="mt-3 flex flex-wrap gap-2 text-[11px] text-zinc-400">
                      {message.meta.route ? <span className="rounded-full border border-zinc-800 px-2 py-1">route: {message.meta.route}</span> : null}
                      {message.meta.sessionId ? <span className="rounded-full border border-zinc-800 px-2 py-1">session: {message.meta.sessionId}</span> : null}
                    </div>
                  ) : null}

                  <div className="mt-3 space-y-3">
                    {Array.isArray(message.blocks) ? message.blocks.map((block, blockIndex) => renderBlock(block, blockIndex)) : null}
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="border-t border-zinc-800 p-4 md:p-5">
            <div className="rounded-2xl border border-zinc-800 bg-zinc-950/70 p-3">
              <div className="mb-3 text-xs uppercase tracking-[0.2em] text-zinc-500">Entrada operativa</div>
              <div className="mb-3 grid grid-cols-1 gap-3 md:grid-cols-[minmax(0,1fr)_220px]">
                <textarea
                  className="min-h-[110px] w-full resize-none rounded-xl border border-zinc-800 bg-zinc-900 px-3 py-3 text-sm text-zinc-100 outline-none placeholder:text-zinc-500"
                  placeholder="Escribe una instrucción, consulta o diagnóstico..."
                  value={input}
                  onChange={(event) => setInput(event.target.value)}
                />
                <div className="rounded-xl border border-zinc-800 bg-zinc-900/60 p-3">
                  <div className="text-[11px] uppercase tracking-[0.2em] text-zinc-500">API base</div>
                  <input
                    className="mt-2 w-full rounded-lg border border-zinc-800 bg-zinc-950 px-3 py-2 text-sm text-zinc-100 outline-none"
                    value={apiBase}
                    onChange={(event) => setApiBase(event.target.value)}
                  />
                  <div className="mt-3 text-[11px] uppercase tracking-[0.2em] text-zinc-500">Módulo activo</div>
                  <div className="mt-2 rounded-lg border border-zinc-800 bg-zinc-950 px-3 py-2 text-sm text-zinc-200">
                    {activeModuleLabel}
                  </div>
                </div>
              </div>

              {error ? (
                <div className="mb-3 rounded-xl border border-red-800/50 bg-red-950/30 px-3 py-2 text-sm text-red-300">
                  {error}
                </div>
              ) : null}

              <div className="mt-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <div className="flex flex-wrap gap-2">
                  {MODULES.map((tag) => (
                    <button
                      key={tag.id}
                      onClick={() => setActiveModule(tag.id)}
                      className={cx(
                        'rounded-full border px-3 py-1 text-xs',
                        activeModule === tag.id
                          ? 'border-zinc-500 bg-zinc-800 text-zinc-100'
                          : 'border-zinc-700 text-zinc-400'
                      )}
                    >
                      {tag.label}
                    </button>
                  ))}
                </div>
                <button
                  onClick={() => void sendMessage(input)}
                  disabled={pending || !input.trim()}
                  className="rounded-2xl border border-zinc-700 bg-zinc-100 px-4 py-2 text-sm font-semibold text-zinc-950 hover:bg-zinc-200 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {pending ? 'Enviando…' : 'Enviar'}
                </button>
              </div>
            </div>
          </div>
        </main>

        <aside className="space-y-4 rounded-2xl border border-zinc-800 bg-zinc-900/70 p-4 shadow-2xl">
          <section className="rounded-2xl border border-zinc-800 bg-zinc-950/60 p-4">
            <div className="text-xs uppercase tracking-[0.2em] text-zinc-500">Estado</div>
            <div className="mt-3 space-y-3">
              {[
                ['Backend', pending ? 'BUSY' : 'OK'],
                ['Ruta', lastReply?.route || 'N/A'],
                ['Sesión', sessionId],
                ['API', apiBase],
              ].map(([label, value]) => (
                <div key={label} className="flex items-center justify-between rounded-xl border border-zinc-800 bg-zinc-900 px-3 py-2 gap-3">
                  <span className="text-sm text-zinc-300">{label}</span>
                  <span className="text-xs font-semibold text-zinc-100 break-all text-right">{value}</span>
                </div>
              ))}
            </div>
          </section>

          <section className="rounded-2xl border border-zinc-800 bg-zinc-950/60 p-4">
            <div className="text-xs uppercase tracking-[0.2em] text-zinc-500">Última respuesta</div>
            <pre className="mt-3 max-h-64 overflow-auto rounded-xl border border-zinc-800 bg-zinc-900 p-3 text-xs text-zinc-300 whitespace-pre-wrap">
{JSON.stringify(lastReply, null, 2)}
            </pre>
          </section>

          <section className="rounded-2xl border border-zinc-800 bg-zinc-950/60 p-4">
            <div className="text-xs uppercase tracking-[0.2em] text-zinc-500">Objetivo actual</div>
            <ul className="mt-3 space-y-2 text-sm text-zinc-300">
              <li>• Consumir POST /api/chat</li>
              <li>• Renderizar reply.blocks</li>
              <li>• Mantener sessionId estable</li>
              <li>• Preparar conexión futura a trace y acciones</li>
            </ul>
          </section>
        </aside>
      </div>
    </div>
  );
}
