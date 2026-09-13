# Runeforge - Hoja de Ruta por Etapas
## De prototipo WhatsApp a sistema estable de bitácoras y hábitos

> Repo: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo
> Owner: forgerrune@gmail.com
> Fecha: 2026-08-15 America/Mexico_City
> Filosofía base: Local-First, pero pragmático. Prototipar en nube, estabilizar en local.

### Objetivo real (no técnico)

**Runeforge me sirve para llevar orden en mi trabajo de telemetría (bitácoras, análisis de problemas, reforma de actividades) y en lo personal para seguir hábitos, rutinas y planeación de proyectos.**

Todo lo demás (Fastify, Ollama, Tailscale, CRDT) es el CÓMO. Esta hoja de ruta prioriza el QUÉ.

---

### Etapa 0 - Estabilizar (1 día) - BLOQUEANTE
**Objetivo:** Cero incendios. No se construye sobre algo roto.

- [ ] Recuperar AWS root forgerrune@gmail.com -> Forgot password? -> EC2 runeforge -> `sudo tailscale set --ssh`
- [ ] Validar `ssh runeforge` sin timeout 100.111.32.10
- [ ] Fix Tailscale NoState Windows: dependencias NlaSvc, excluir de limpiadores de registro
- [ ] `pm2 list` relay 46MB backend 52MB online, `/api/ollama/status` ok:true count:4

**Entregable:** `desktop-ndfe0b0` 100.83.105.117 <-> `runeforge` 100.100.167.48 SSH ok.
**Criterio de salida:** Puedes entrar a runeforge por Tailscale.

### Etapa 1 - Prototipo Bitácora WhatsApp (HOY - 1 tarde) - MAYOR VALOR
**Objetivo:** Capturar por WhatsApp y guardar estructurado. Probar el patrón captura->guardar->recuperar.

**Stack:** n8n cloud forgerrune.app.n8n.cloud (vacío) + WhatsApp Business Cloud + Data Tables

**Data Table `bitacoras`:**
```
fecha: datetime (auto)
tipo: enum [telemetria, bitacora, problema, actividad, habito, tarea]
proyecto: string [Ciner, Personal, Otro]
texto: string largo
estado: enum [pendiente, en_progreso, resuelto, hecho]
origen: whatsapp
```

**Workflow 1 - Captura:**
```
WhatsApp Trigger -> Set (parsea "Ciner: falló sensor km 42") -> Data Table Add Row -> WhatsApp Reply "✅ Guardado"
```

**Workflow 2 - Resumen diario 19:00:**
```
Schedule 19:00 -> Data Table List hoy -> Agrupar por proyecto/tipo -> WhatsApp Send resumen
```

**Entregable:** Escribes por WhatsApp y queda guardado. Resumen diario automático.
**Criterio de salida:** Usas 3 días seguidos sin fallar. Si no lo usas, no sirve.

### Etapa 2 - Motor Unificado (3 días)
**Objetivo:** Mismo motor para trabajo + personal. Reusar tabla, no crear 6 sistemas.

**Acciones:**
- [ ] Añadir vistas: Telemetría / Problemas / Hábitos / Proyectos (filtros sobre misma tabla)
- [ ] Análisis simple con Ollama local: `qwen2.5:1.5b` resume "¿qué problemas se repiten esta semana en Ciner?"
- [ ] Plantillas rápidas WhatsApp:
  - `T Ciner sensor X km 42` -> telemetria
  - `P Ciner falla Y` -> problema
  - `H ejercicio 30min` -> habito
  - `A proyecto Z tarea` -> actividad

**Entregable:** Un solo chat para todo. Preguntas: "¿qué pendientes tengo de Ciner?"
**Criterio de salida:** Puedes responder auditoría de trabajo de la semana en 2 minutos.

### Etapa 3 - Soberanía Local (4 días) - Opcional pero recomendado
**Objetivo:** Mover de n8n cloud a local para 100% offline, coherente con filosofía.

**Acciones:**
- [ ] Docker Compose en runeforge: n8n + Ollama + Postgres + Qdrant (patrón comunidad 11 workflows sin API keys)
- [ ] `tailscale serve --bg --https=443 http://localhost:5678` -> https://runeforge.tail12b297.ts.net
- [ ] Migrar Data Tables -> SQLite WAL local (tu stack actual)
- [ ] WhatsApp: migrar de Business Cloud a Evolution API con tu número personal (más soberano)

**Entregable:** n8n local funcionando en 100.100.167.48, sin depender de nube.
**Criterio de salida:** Apagas internet y puedes seguir capturando (queda en cola y sincroniza).

### Etapa 4 - Higiene y Números Honestos (1 tarde)
**Objetivo:** Devolver credibilidad. Sistema autorreparable de verdad.

- [ ] Re-benchmark Ollama en tu hardware: `ollama-benchmark` con 4 modelos. Actualizar README: 110.80 tok/s -> valor real medido (esperado ~26-30 tok/s en 3B Q4 en GTX 1660)
- [ ] Backup automático SQLite WAL checkpoint + copia diaria
- [ ] Script `runeforge_launcher.ps1` que levanta y verifica salud (ya lo tienes, asegurar que valida no solo lanza)
- [ ] Actualizar README: separar "medido" vs "benchmark oficial" vs "aspiracional"
- [ ] Decidir mensaje: "local-first híbrido con puentes cloud opcionales" vs "100% offline"

**Entregable:** README honesto, backup, checklist recuperación.
**Criterio de salida:** Alguien nuevo puede clonar y levantar en 3 comandos sin sorpresas.

### Etapa 5 - Expansión Opcional (Solo si Etapa 1-4 estable)
**Objetivo:** Solo lo que pasa la prueba "¿qué se rompe si lo quito?"

- [ ] Headscale self-hosted: solo si necesitas soberanía total del control plane Tailscale. Candidata a congelar.
- [ ] CRDTs Automerge/Yjs: solo si necesitas colaboración multiusuario real. Si eres solo tú, peso muerto 320kB WASM. Congelar por ahora.
- [ ] PWA offline avanzada: solo si necesitas captura sin señal en campo por horas.
- [ ] AWS Agent Toolkit: `aws configure agent-toolkit --region us-east-1` (servicio solo us-east-1)

**Regla:** No entrar a Etapa 5 si Etapa 1 no tiene 7 días de uso real.

---

### Mapa visual

```
HOY -> [Etapa 0: Estabilizar 1d] -> [Etapa 1: WhatsApp Bitácora HOY]
                                      |
                                      v
                              Usas 3 días -> ¿te sirve?
                                      |
                                Sí -> [Etapa 2: Motor Unificado 3d]
                                      |
                                      v
                              [Etapa 3: Local Soberano 4d] -> [Etapa 4: Higiene 1 tarde]
                                      |
                                      v
                              [Etapa 5: Opcional - solo si todo lo anterior sólido]
```

### Próximos pasos inmediatos (para ti)

1. Crear Data Table `bitacoras` en forgerrune.app.n8n.cloud
2. Configurar WhatsApp Business Cloud (Phone Number ID + Token)
3. Importar workflow captura que te paso

### Cómo actualizar el repo

```bash
git clone https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git
cd runeforge-v2-nucleo
# copia este archivo a la raíz
cp /ruta/a/ROADMAP_ETAPAS_Runeforge.md ./ROADMAP.md
# o si ya tienes ROADMAP.md, reemplaza
git add ROADMAP.md
git commit -m "docs: roadmap por etapas enfocado en bitácoras WhatsApp + telemetría"
git push origin main
```

Alternativa: súbelo manual desde GitHub web > Add file > Upload files.

---

### Nota crítica

Esta hoja de ruta recorta 70% de complejidad inicial. No es que CRDTs o Headscale sean malos, es que para telemetría + hábitos son sobre-ingeniería para usuario único. Primero valor diario, luego filosofía.

El potencial de Runeforge es real. El riesgo es morir de complejidad antes de entregar valor. Esta ruta evita eso.
