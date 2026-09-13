# Análisis Autónomo - Núcleo Runeforge C:\RUNEFORGE_V2_CORE

## Estado detectado tree 2026-08-15 21:14:05

### Estructura raíz C:\
```
C:\
├── RUNEFOGE_PRO (typo, debería ser RUNEFORGE_PRO) - Entorno activo
├── RUNEFORGE_V2_CORE - Núcleo estable v2.6.2 VERDE+LLM [ACTIVO]
├── RUNEFORGE - Legacy
├── RUNEFORGE_BACKUPS
├── RUNEFOGETEST
├── RUNEFOGE_PRO.zip 4.2GB - Backup comprimido
└── RUNEFORGE_FULL_BACKUP_20260730_231515.zip 6.0GB
```

**Hallazgo crítico:** 2 nombres similares con typo:
- `C:\RUNEFOGE_PRO` (sin R) - entorno que reportas como activo
- `C:\RUNEFORGE_V2_CORE` - núcleo donde corre tree

Recomendación: Unificar a `C:\RUNEFORGE_V2_CORE` como único source of truth. `RUNEFOGE_PRO` mover a backup.

### Estructura RUNEFORGE_V2_CORE - Análisis por capas

#### ✅ Capas sanas
```
config/ -> ok
data/
  ├── commander/ -> ok
  ├── processed/ -> ok (vacío, listo para Etapa 1)
  ├── raw/ -> ok
  └── traces/ -> ok
infra/headscale/
  ├── config/ -> ok
  │   └── data/ -> DUPLICADO: infra/headscale/config/data y infra/headscale/data (mismo nivel)
  └── data/ -> duplicado, revisar
src/backend/services/llm/adapters/ -> factory createProvider('ollama') - núcleo LLM
src/relay/ -> PM2 relay
public/forge/swarm/ -> PWA 10 pestañas
```

#### ⚠️ Duplicación crítica - knowledge/
```
knowledge/
├── 00_INBOX/whatsapp_raw/2026-05-02__chat_personal__raw_zip
├── 03_AUDITS/inventories/
├── graph/
├── markov/
├── memoria-ia/
│   ├── 00_raw_imports/
│   ├── 01_normalized/PROJECTS/
│   ├── 02_rules/
│   └── 03_logs/
├── memoria-ia-pack/
└── RUNEFORGE_KNOWLEDGE/  <- DUPLICADO ANIDADO, replica toda la estructura
    ├── 00_INBOX/whatsapp_raw/2026-05-02__chat_personal__raw_zip (duplicado)
    ├── 03_AUDITS/
    ├── memoria-ia/
    └── memoria-ia-pack/backups/install_20260519_001432
```

**Impacto:** Estás procesando doble. `knowledge/RUNEFORGE_KNOWLEDGE/` es un backup dentro del propio knowledge. Debe moverse a `C:\RUNEFORGE_BACKUPS\`

**Acción autónoma recomendada:**
```powershell
Move-Item C:\RUNEFORGE_V2_CORE\knowledge\RUNEFORGE_KNOWLEDGE C:\RUNEFORGE_BACKUPS\RUNEFORGE_KNOWLEDGE_$(Get-Date -Format yyyyMMdd)
```

#### 🎯 Oportunidad Etapa 1 - WhatsApp ya tiene datos
```
knowledge/00_INBOX/whatsapp_raw/2026-05-02__chat_personal__raw_zip
```
Este zip es oro para tu prototipo. Es exactamente lo que n8n Data Tables debe ingerir.

**Ruta lógica:**
```
00_INBOX/whatsapp_raw (crudo)
  -> data/raw/whatsapp (descomprimido)
  -> scripts normalización -> data/processed/bitacoras.json
  -> knowledge/01_normalized/PROJECTS/
```

#### 🗑️ node_modules/
Presente en C:\RUNEFORGE_V2_CORE\node_modules (cientos de subcarpetas fastify, ajv, pino)
- Debe estar en .gitignore
- No debe incluirse en zip backups (explica 4.2GB y 6GB zips gigantes)

#### 📁 public/documentacion y propuestas/
Contiene docs dispersas. Migrar a docs/jugo/ para unificar.

### Diagnóstico rápido por filosofía Local-First

| Componente | Estado | Acción |
|------------|--------|--------|
| Fastify backend | ✅ node_modules presente, src/backend ok | Validar `pm2 list` |
| Ollama | ⚠️ No visible en tree, debe estar en servicio Windows | `Invoke-RestMethod http://localhost:3100/api/ollama/status` |
| SQLite WAL | ⚠️ No visible db file, buscar en data/ o config/ | `dir C:\RUNEFORGE_V2_CORE\*.db -Recurse` |
| PWA 10 tabs | ✅ public/forge/swarm ok | Validar http://localhost:3100 |
| Tailscale | ✅ infra/headscale config ok pero duplicado | Limpiar duplicado data/ |
| WhatsApp raw | ✅ 2026-05-02 zip presente | Usar como fuente Etapa 1 |
| Backups 4.2GB+6GB | ⚠️ Incluyen node_modules, duplican | Recrear sin node_modules |

### Acciones autónomas propuestas (orden ejecución)

**Ahora (5 min):**
1. Mover RUNEFORGE_KNOWLEDGE duplicado a backups
2. Corregir typo RUNEFOGE_PRO -> documentar como legacy
3. Limpiar infra/headscale duplicado

**Etapa 1 (Hoy):**
4. Descomprimir whatsapp_raw 2026-05-02 a data/raw/whatsapp/
5. Crear Data Table bitacoras en n8n cloud y mapear campos
6. Crear script bootstrap_etapa1.ps1

**Etapa 2 (Mañana):**
7. Normalizar whatsapp_raw -> JSON estructurado -> memoria-ia/01_normalized
8. .gitignore: agregar node_modules, data/raw, knowledge/00_INBOX

### Comandos de verificación autónoma

```powershell
# En C:\RUNEFORGE_V2_CORE
.\runeforge_launcher.ps1 # si existe
pm2 list
Invoke-RestMethod http://localhost:3100/api/ollama/status
Get-ChildItem knowledge/00_INBOX/whatsapp_raw -Recurse | Measure-Object
dir C:\ -Filter RUNEFORGE* | Select Name, Length
```
