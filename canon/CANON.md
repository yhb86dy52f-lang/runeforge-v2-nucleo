# RUNEFORGE :: CANON v1.0

> **Un solo comando convierte cualquier HTML autocontenido en app nativa Windows.**
> Sin npm, sin Node, sin Vite. Solo Rust y `cargo build --release`.

**Versión:** 1.0
**Congelado:** 2026-09-20
**Estado:** Operativo y validado en producción

---

## 1. Resumen ejecutivo

Este canon define el **estándar inmutable** para construir aplicaciones de escritorio
RUNEFORGE. Nace tras resolver bloqueadores estructurales de Node.js en Windows y
se apoya exclusivamente en el toolchain de Rust + Tauri v2.

**Promesa:**
- HTML autocontenido → `.exe` nativo en ~20 segundos (caché caliente)
- 100% offline, cero dependencias de red
- Binario final: ~3 MB con optimizaciones agresivas
- Sin instaladores previos más allá de Rust

**Fábrica:** `C:\RUNEFORGE_V2_CORE\scripts\Nexus-Forge.ps1`

---

## 2. Los 12 Mandamientos

### I. Un solo HTML autocontenido es la unidad de distribución

Todo el frontend (React, Tailwind, lucide, CSS, fuentes) va inline en un único
`.html`. Cero dependencias externas, cero CDN, cero `node_modules`.

**Justificación:** garantiza distribución offline-first y hace el HTML trivialmente
inspeccionable y versionable.

### II. Nunca se invoca Node.js, npm, npx ni Vite

El error `ERR_SSL_CIPHER_OPERATION_FAILED` es estructural en Windows + Node 17+
(OpenSSL 3 con cipher GCM). La única salida limpia es no usar Node.

**Justificación:** intentos con `--openssl-legacy-provider`, `strict-ssl=false`,
registros HTTP y espejos fallan de forma no determinista.

### III. Solo `cargo build --release`

`cargo tauri dev` requiere `cargo-tauri` instalado globalmente. `cargo build`
es el comando base de Rust, siempre disponible.

**Justificación:** reduce superficie de fallo y dependencias.

### IV. Cargo siempre con HTTP/1.1, retry=10 y sparse protocol

El archivo `~/.cargo/config.toml` es **global y permanente**:

```toml
[http]
multiplexing = false
timeout = 300
low-speed-limit = 1

[net]
retry = 10
git-fetch-with-cli = true

[registries.crates-io]
protocol = "sparse"
```

**Justificación:** `multiplexing = false` elimina `SEC_E_DECRYPT_FAILURE` de
schannel con HTTP/2. `retry = 10` amortigua caídas de Cloudflare.
`sparse` es más ligero que el index por git.

### V. Fallback a espejo cuando el CDN oficial falla

Si el CDN de crates.io falla tras 2 intentos, conmutar a
`https://mirrors.ustc.edu.cn/crates.io-index/`.

**Justificación:** el espejo USTC usa otro stack TLS que no rompe con schannel.

### VI. Rutas absolutas siempre

Ningún script depende de `$PWD`. Todo apunta a `C:\RUNEFORGE_V2_CORE\...`.

**Justificación:** elimina fallos por directorio de trabajo incorrecto y hace
los scripts invocables desde cualquier shell.

### VII. Limpieza de procesos antes de reescribir

`Get-Process -Name <bin> | Stop-Process -Force` + `Start-Sleep -Milliseconds 400`
antes de `Remove-Item`.

**Justificación:** sin esto, `Remove-Item` falla con `EPERM` por handle bloqueado.

### VIII. Iconos generados in-situ con `System.Drawing`

Gradiente cyan (`#00F5FF`) → magenta (`#FF00FF`) a 45° con núcleo oscuro
(`#080A12`) y dot cyan. Consistencia visual entre todas las apps RUNEFORGE.

**Justificación:** cero dependencias externas de assets, iconos siempre presentes.

### IX. Iconos con `icon.ico` escrito a mano

Formato ICONDIR + PNG embebido, construido con `BinaryWriter`.

**Justificación:** sin esto, `tauri build` falla con "icon not found" o
"invalid ICO format" al empaquetar.

### X. Perfil release siempre optimizado

```toml
[profile.release]
opt-level = "s"      # tamaño mínimo
lto = true           # link-time optimization
strip = true         # sin símbolos de debug
codegen-units = 1    # máxima optimización
panic = "abort"      # sin unwinding -> más pequeño
```

**Justificación:** reduce el binario de ~15 MB a ~3 MB.

### XI. Ejecución siempre en PowerShell real

El wrapper de forja interpreta cada línea como `Get-Process <comando>`. Todo
script debe correr en `powershell.exe` o `pwsh.exe` limpios.

**Justificación:** el wrapper hace imposible ejecutar scripts multilinea.

### XII. Distribución offline-first

El `.exe` resultante no toca la red jamás. Si el HTML tiene llamadas externas,
se documentan como opcionales y la app debe funcionar degradada sin ellas.

**Justificación:** previsible en entornos sin conectividad, auditable.

---

## 3. Anatomía de una app canónica

```
C:\RUNEFORGE_V2_CORE\apps\<nombre>\
├── dist\
│   └── index.html                    <- bundle único (HTML + CSS + JS inline)
└── src-tauri\
    ├── Cargo.toml                    <- metadata + perfil release optimizado
    ├── build.rs                      <- tauri_build::build()
    ├── tauri.conf.json               <- config de ventana y bundle
    ├── capabilities\
    │   └── default.json              <- permisos Tauri v2
    ├── icons\
    │   ├── 32x32.png
    │   ├── 128x128.png
    │   ├── 128x128@2x.png
    │   ├── icon.png                  <- 512x512 master
    │   └── icon.ico                  <- ICONDIR + PNG embebido
    └── src\
        ├── main.rs                   <- entry point
        └── lib.rs                    <- lógica

```

**Artefacto final:** `src-tauri\target\release\<nombre>.exe`

---

## 4. Uso de la fábrica

### Invocación básica

```powershell
C:\RUNEFORGE_V2_CORE\scripts\Nexus-Forge.ps1 `
    -Name "mi-app" `
    -Html "C:\ruta\al\index.html"
```

### Parámetros completos

| Parámetro | Requerido | Default | Descripción |
|---|---|---|---|
| `-Name` | Sí | — | Nombre del binario (sin espacios, kebab-case) |
| `-Html` | Sí | — | Ruta absoluta al HTML fuente |
| `-Title` | No | `$Name` | Título de la ventana |
| `-Width` | No | `1440` | Ancho inicial |
| `-Height` | No | `900` | Alto inicial |
| `-Identifier` | No | `com.runeforge.<name>` | Bundle identifier |
| `-Bundle` | No | off | Genera `.msi` + `.exe` NSIS |
| `-Run` | No | on si no `-Bundle` | Lanza la app al terminar |

### Ejemplos

```powershell
# Mínimo: compilar y lanzar
.\Nexus-Forge.ps1 -Name "mi-app" -Html "C:\ruta\index.html"

# Con título personalizado
.\Nexus-Forge.ps1 `
    -Name "panel-cliente" `
    -Html "C:\proyectos\panel\dist\index.html" `
    -Title "Panel Cliente - ACME"

# Distribuir: compilar + MSI + NSIS
.\Nexus-Forge.ps1 `
    -Name "mi-app" `
    -Html "C:\ruta\index.html" `
    -Bundle

# Tamaño de ventana custom
.\Nexus-Forge.ps1 `
    -Name "kiosk" `
    -Html "C:\ruta\index.html" `
    -Width 1920 -Height 1080
```

---

## 5. Checklist de pre-flight

Antes de forjar cualquier HTML, verificar:

```
[ ] El HTML abre correctamente en Edge/Chrome (doble clic)
[ ] No hay <script src="https://cdn..."> sin SRI (rompe offline)
[ ] No hay imports a fuentes externas sin fallback local
[ ] El HTML pesa < 500 KB (idealmente < 250 KB)
[ ] No requiere red para renderizar UI inicial
[ ] Tiene manejo de error si navigator.clipboard no existe
[ ] Funciona con window.location.protocol === "tauri:"
```

**Nota:** si el archivo proviene de otro equipo, Windows lo marca como
"bloqueado". Ejecutar antes:

```powershell
Unblock-File "C:\ruta\al\index.html"
```

---

## 6. Troubleshooting

### `ERR_SSL_CIPHER_OPERATION_FAILED` (npm)

**Causa:** OpenSSL 3 de Node 17+ rompe con cipher GCM en Windows.
**Solución:** no usar Node. Ver Mandamiento II.

### `SEC_E_DECRYPT_FAILURE` (cargo)

**Causa:** schannel falla al descifrar frames HTTP/2 de crates.io.
**Solución:** `multiplexing = false` en `~/.cargo/config.toml`.

### `EPERM` / `ENOTEMPTY` al borrar directorio

**Causa:** proceso vivo mantiene handle abierto.
**Solución:** matar proceso, esperar 400 ms, `rmdir /s /q` nativo.

### `cargo tauri: no such command`

**Causa:** `cargo-tauri` no está instalado globalmente.
**Solución:** usar `cargo build --release` directo, o instalar con
`cargo install tauri-cli --version "^2" --locked`.

### `Token inesperado` al parsear script con heredocs

**Causa:** PowerShell cierra el heredoc en el primer `'@` en inicio de línea,
incluso dentro de otro heredoc.
**Solución:** nunca anidar `@'...'@`. Un solo heredoc externo como máximo.
Para escribir strings multilinea complejos, usar arrays de strings + `[IO.File]::WriteAllText`.

### Ventana en blanco

**Causa:** CSP bloqueando recursos, o el HTML no maneja el protocolo `tauri:`.
**Solución:** abrir DevTools con `Ctrl+Shift+I` (disponible en build de dev).
Verificar `security.csp: null` en `tauri.conf.json`.

---

## 7. Anti-patrones (nunca hacer)

| Anti-patrón | Por qué | Alternativa |
|---|---|---|
| Usar `create-vite` en Windows | Falla por SSL GCM | Scaffold manual |
| `npx tailwindcss init` | Ejecuta Node | Tailwind precompilado inline |
| `cargo tauri dev` como requisito | Requiere cargo-tauri | `cargo build --release` |
| Poner API keys en el frontend | Robables desde DevTools | Backend o localStorage |
| Asumir que el HTML está en `$PWD` | Scripts fallan según cwd | Rutas absolutas |
| Confiar en el wrapper forja para builds | Intercepta comandos | PowerShell real |
| `cargo build` sin `--release` | Binario 50 MB | `--release` siempre |
| Heredocs anidados en PowerShell | El parser los corta | Arrays de strings |

---

## 8. Tabla de versiones del canon

| Versión | Fecha | Cambio | Estado |
|---|---|---|---|
| v1.0 | 2026-09-20 | Canon inicial. 12 mandamientos. Fábrica funcional. | **Congelado** |

**Reglas de versionado:**

Cambios solo si:
1. Tauri rompe compatibilidad en major.
2. Se descubre un fallo de seguridad en el toolchain.
3. Se documenta un caso límite que rompe los 12 mandamientos.

Cualquier otro cambio va a `v1.x` (parche) sin modificar los mandamientos.

---

## 9. Apps forjadas bajo este canon

| App | HTML fuente | Peso EXE | Fecha | Estado |
|---|---|---|---|---|
| `nexus-lab` | `forja\laboratorio.html` | 2.94 MB | 2026-09-20 | Operativo |
| `openwash-real` | `D:\UserData\Desktop\Html\Html\Openwash-Real-Comercial-Html.html` | ~3 MB | 2026-09-20 | En compilación |

---

## 10. Extensiones previstas

El canon acepta cualquier HTML autocontenido. Casos de uso inmediatos:

- **Dashboards internos** de PM2 / Ollama / Fastify en un solo HTML
- **Herramientas de campo** para LMU-2630 (versión desktop de la HMI)
- **Visores de reportes** RUNEFORGE (`RUNEFORGE_REPORT.txt` → HTML → EXE)
- **Clientes de API** contra backend Fastify local (`fetch("http://localhost:3000")`)
- **Dashboards IoT** que consultan Tailscale por WebSocket

**Regla de escalado:** cualquier HTML que hoy se abre en el navegador puede
convertirse en `.exe` en ~20 segundos con `Nexus-Forge.ps1`.

---

## 11. Próximos pasos planificados

### v1.1 (pendiente)

- Compartir `target-dir` entre todas las apps (`CARGO_TARGET_DIR`)
- Efecto: la 1ª app tarda 10 min, las siguientes 20 s

### v1.2 (futuro)

- `Validate-App.ps1` para auditar apps contra el canon
- Plantilla opcional con barra de menú nativa Tauri
- Sistema de actualizaciones offline (bundles incrementales)

---

## 12. Contacto y ubicación

- **Raíz canon:** `C:\RUNEFORGE_V2_CORE`
- **Fábrica:** `C:\RUNEFORGE_V2_CORE\scripts\Nexus-Forge.ps1`
- **Apps:** `C:\RUNEFORGE_V2_CORE\apps\<nombre>\`
- **Cargo config:** `%USERPROFILE%\.cargo\config.toml`
- **Documentación:** `C:\RUNEFORGE_V2_CORE\docs\`

---

*Este documento es la fuente de verdad. Cualquier desviación del canon debe
justificarse aquí antes de implementarse.*
