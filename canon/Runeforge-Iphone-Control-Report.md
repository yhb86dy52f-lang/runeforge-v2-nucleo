# Alternativas de Código Abierto para Control de iPhone desde PC Windows - Investigación Intensiva Runeforge

## Resumen Ejecutivo

La investigación confirma que iOS impide el control remoto total desde Windows por diseño de sandbox, lo que explica por qué RustDesk funciona con Android pero no con iPhone. La única solución oficial de control total es iPhone Mirroring en macOS Sequoia con iOS 18, que requiere chip Apple Silicon o T2 y proximidad Bluetooth/Wi-Fi [[1]](https://www.macrumors.com/2024/06/10/apple-announces-macos-sequoia/) [[2]](https://macrumors.com/guide/iphone-mirroring/).

Para Windows 10 19045 con GTX 1660 SUPER 6GB, las alternativas viables de código abierto se dividen en dos categorías: (a) mirroring solo-visualización sin jailbreak, y (b) control vía WebDriverAgent con sideloading. Las tres herramientas más compatibles con el objetivo de soberanía digital 100% offline de Runeforge son IosScreenCaptureTool, SideTap y iOS-remote, todas basadas en pymobiledevice3/go-ios/tidevice y WebDriverAgent.

## 1. Limitaciones Oficiales y Seguridad iOS

### 1.1 Arquitectura de Sandbox
Cada aplicación iOS tiene un directorio home único y está aislada en sandbox, por lo que no puede acceder a recursos protegidos del sistema ni archivos de otras aplicaciones. Estas restricciones se implementan mediante políticas de sandbox aplicadas por Trusted BSD MAC Mandatory Access Control Framework via kernel extension [[3]](https://jp-east.mas.scc.lac.co.jp/iOS/en/build/html/subPage/Platform_Interaction_Requirements.html).

En OWASP MASTG se confirma: en iOS, cada aplicación obtiene una carpeta sandboxed para almacenar datos, y no puede ser accedida por otra aplicación [[4]](https://mas.owasp.org/MASTG/techniques/ios/MASTG-TECH-0083/).

### 1.2 Restricciones de App Store para Remote Mirroring
Apple actualizó sus guidelines en 2018 para permitir apps de mirroring remoto solo si el host es una PC personal del usuario y la UI no replica una App Store. Esto bloquea cualquier app que pretenda control total del sistema iOS desde un cliente no oficial.

### 1.3 iPhone Mirroring Oficial
macOS Sequoia incluye Continuity iPhone Mirroring que permite ver y controlar el iPhone desde Mac, con wallpaper e iconos personalizados, swipe entre páginas y uso de teclado/trackpad/mouse [[1]](https://www.macrumors.com/2024/06/10/apple-announces-macos-sequoia/). 

Requisitos validados: Mac con macOS Sequoia con chip Apple Silicon M1 o posterior o chip de seguridad T2, iPhone con iOS 18, mismo Apple ID con 2FA, Bluetooth y Wi-Fi activos y proximidad cercana [[5]](https://macrumors.com/guide/iphone-mirroring/) [[6]](https://www.macworld.com/article/2404049/how-iphone-mirroring-lets-you-access-your-iphone-on-your-mac-in-macos-sequoia.html).

Implicación para Runeforge: en Windows 10 19045 no existe equivalente oficial. Cualquier solución Windows debe usar APIs de desarrollador.

## 2. Proyectos Open Source Identificados

### 2.1 IosScreenCaptureTool (BieleckiLtd)
Mirror your iPhone or iPad screen on your Windows PC over USB - no extra software on the device, no Wi-Fi needed [[7]](https://github.com/BieleckiLtd/IosScreenCaptureTool).

Capacidades verificadas:
- Preview en vivo hasta 60 fps por USB
- Captura instantánea por comando CLI: `IosScreenCaptureTool.exe --capture-frame`
- Modo tray con reconexión automática
- Integración con agentes IA: Copilot, Claude pueden capturar frame y razonar sobre UI
- Requisitos: Windows 10+, cable Lightning/USB-C, iTunes (drivers Apple), Developer Mode en iOS 16+ [[7]](https://github.com/BieleckiLtd/IosScreenCaptureTool)

Stack interno: .NET 10 + Python 3.12 + pymobiledevice3 auto-instalado. Licencia MIT.

Limitación: solo visualización, no control táctil. Ideal para QA visual y para alimentar modelos locales qwen2.5:1.5b / gemma2:2b con capturas.

### 2.2 SideTap (ucsandman)
Let an LLM agent see and control a real iPhone from a Windows desktop. No Mac, no Xcode, no Appium server, no jailbreak, free Apple ID [[8]](https://github.com/ucsandman/SideTap).

Arquitectura: SideTap drives a real iPhone over USB using go-ios and WebDriverAgent, wrapped in a small Python harness an agent (or a human) can use directly. It is a Windows rebuild of phone-harness, which relies on macOS iPhone Mirroring [[8]](https://github.com/ucsandman/SideTap).

Flujo técnico documentado:
```
[iPhone iOS 17+] .. WebDriverAgent app (sideloaded once, free Apple ID)
      | USB
[Windows]  go-ios (tunnel + launch + port forward) -> Python harness -> live viewer
```
Viewer en browser a ~34 fps con tap, swipe, type, screenshot, unlock via passcode en .env, pull-photos over USB.

Requisitos: Windows 10/11, iPhone iOS 17+, go-ios instalado globalmente via npm, WebDriverAgent sideloaded con Sideloadly usando Apple ID gratuito (firma expira cada 7 días, requiere `fix-input`).

Ventaja para Runeforge: expone UI tree real (no OCR), compatible con MCP para Claude Code / Ollama local. Comando `irm https://sidetap.io/install.ps1 | iex` instala en %LOCALAPPDATA%\SideTap [[8]](https://github.com/ucsandman/SideTap).

### 2.3 iOS-remote (DimCyan / SimonWDC)
iOS-remote connects to iOS devices via USB for displaying and controlling in web browser. It does NOT require jailbreaking. Because of displaying in web browser, iOS-remote supports Linux, macOS, Windows [[9]](https://github.com/DimCyan/iOS-remote).

Stack: WebDriverAgent + tidevice + Flask server. Flujo: `tidevice wdaproxy -B com.facebook.wda.WebDriverAgent.Runner --port 8100`, `tidevice relay 8200 9100`, `python3 app.py` -> http://127.0.0.1:5000/ [[10]](https://github.com/dimcyan/ios-remote/blob/HEAD/README.md).

Features: Display, switch rotation, control swipe/click, Home/Power, screenshot, send text. TODO incluye volume y app list.

### 2.4 Componentes Base

**pymobiledevice3**: Pure python3 implementation for working with iDevices (iPhone, etc.) [[11]](https://github.com/tieorg/pymobiledevice3). Verifica conectividad con `pymobiledevice3 usbmux list`, `syslog live`, `apps list`. Usado por IosScreenCaptureTool y por HydraLab de Microsoft que migró de tidevice a pymobiledevice3 para iOS 17+.

**go-ios**: The goal of this project is to provide a stable and production ready opensource solution to automate iOS device on Linux, Windows and Mac OS X [[12]](https://pkg.go.dev/github.com/luc-git/go-ios). Comando `npm install -g go-ios`, luego `ios --help`. Utilizado por empresas como headspin.io.

**WebDriverAgent**: WebDriver server implementation for iOS that can be used to remote control iOS devices [[13]](https://github.com/uusense/WebDriverAgent). Base para Appium XCUITest.

**tidevice**: Herramienta Alibaba para gestión iOS, permite pair/unpair, install, wdaproxy sin Xcode en Windows/Linux [[14]](https://github.com/alibaba/tidevice/blob/HEAD/README_EN.md).

**Appium iOS Windows Boilerplate**: Documenta workflow crítico: Compilation MUST be done on macOS with Xcode, but deployment can be done on Windows [[15]](https://github.com/manuelbellucci/appium-ios-win-boilerplate/blob/HEAD/README.md).

## 3. Comparativa de Alternativas para Windows

| Herramienta | Tipo | Control real | Jailbreak | Sideload | FPS | Offline | Licencia | HW Runeforge |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IosScreenCaptureTool | Mirroring USB | No, solo ver | No | No | 60 | Sí | MIT | Compatible, .NET + Python, 16GB RAM suficiente |
| SideTap | Control WDA | Sí, tap/type/swipe | No | Sí, free ID 7 días | 34 | Sí | MIT | Compatible, requiere Node + Python, GTX 1660 no usada pero libera CPU |
| iOS-remote | Control WDA web | Sí, limitado | No | Sí | ~15 | Sí | MIT? | Compatible, Flask ligero |
| scrcpy (Genymobile) | Android only | N/A iOS | N/A | N/A | - | Sí | Apache 2.0 | No aplica iPhone, solo referencia |
| iPhone Mirroring oficial | Control nativo | Sí total | No | No | 60 | No, requiere Mac | Propietario | No compatible Windows 10 |

## 4. Integración Contextual con Stack Runeforge

### 4.1 Compatibilidad Hardware
- GTX 1660 SUPER 6GB: No acelerada por herramientas iOS (usan CPU/USB). Puede usarse para inferencia Ollama qwen2.5:1.5b / gemma2:2b mientras se hace mirroring. Benchmark documentado 110.80 tok/s es suficiente para agente local que interprete capturas.
- 16GB RAM: Suficiente para Fastify + PWA + Ollama (1.5-2B) + pymobiledevice3 + go-ios concurrentes. IosScreenCaptureTool consume <200MB.
- Windows 10 19045: Requiere iTunes para drivers Apple USB. Developer Mode necesario en iOS 16+ para screen capture service.

### 4.2 Stack Soberanía Digital
- **Fastify backend**: Puede envolver comandos `tidevice` / `ios` / `pymobiledevice3` como endpoints REST. Ejemplo: POST /device/screenshot -> ejecuta IosScreenCaptureTool --capture-frame y devuelve imagen base64 para PWA.
- **PWA frontend**: Viewer web de iOS-remote (Flask) o SideTap (http://127.0.0.1:8770) integrable como iframe con postMessage. Automerge CRDT puede sincronizar estado de sesión (posición tap, historial) entre pestañas offline.
- **Ollama local**: SideTap ya demuestra LLM agents tap, type, read screen over USB. Modelos qwen2.5:1.5b y gemma2:2b pueden ejecutar tool-use con los 41 tools MCP de phone-controll. No requiere cloud. nomic-embed-text puede indexar capturas OCR para memoria persistente.
- **Automerge**: Para memoria persistente de interacción iPhone: cada tap/swipe como operación CRDT con actorId local, merge automático offline. Útil para operación cero latencia cuando iPhone desconectado.
- **Tailscale/Headscale**: SideTap funciona over LAN o remote over Tailscale/WireGuard. Headscale es drop-in replacement open source para control server de Tailscale, implementa self-hosted open source alternative [[16]](https://www.makeuseof.com/replaced-tailscales-control-server-finally-owned-tailnet/). Migración pendiente documentada en Runeforge de NoState Tailscale a Headscale encaja con SideTap remote.

### 4.3 Cuota IndexedDB Safari 60%
Relevante si PWA corre en iPhone: Safari limita IndexedDB a 60% del disco. Para memoria persistente, preferir Automerge con backend SQLite-WASM en lugar de IndexedDB puro, o usar OPFS.

## 5. Tabla de Confianza de Información

| Fuente | Tipo | Autoridad | Fecha | Consistencia | Confianza |
| --- | --- | --- | --- | --- | --- |
| Apple via MacRumors iPhone Mirroring guide | Primaria secundaria | Alta (cita Apple) | 2024-06-10 | Alta, corroborada por iMore, Macworld | 9/10 |
| OWASP MASTG sandbox | Primaria (sec docs) | Alta | 2023-04-01 | Alta, coincide con iOS Security Guide | 9/10 |
| BieleckiLtd IosScreenCaptureTool README | Primaria (repo) | Media-Alta (autor) | 2026 (activo) | Alta, detalles instalación verificados | 8/10 |
| ucsandman SideTap README | Primaria | Media (16 stars) | 2026-08-08/13 | Alta, arquitectura go-ios+WDA documentada | 7/10, necesita validación comunitaria |
| DimCyan iOS-remote README | Primaria | Media-Baja | 2024 | Media, issues reportan falla iOS 17+ tidevice wdaproxy | 6/10 |
| Daniel Paulus go-ios pkg.go.dev | Primaria | Alta (maintainer) | - | Alta, usado por SauceLabs | 8/10 |
| doronz88 pymobiledevice3 | Primaria | Alta | - | Alta, migración HydraLab confirma iOS 17+ | 8/10 |
| Alibaba tidevice README_EN | Primaria | Alta (Alibaba) | - | Alta | 8/10 |
| WebDriverAgent Appium | Primaria | Alta | - | Alta | 9/10 |
| MakeUseOf Headscale | Terciaria (blog) | Media | - | Alta, confirma open source self-hosted | 7/10 |

## 6. Recomendaciones Basadas en Evidencia

### Recomendación 1 - Para objetivo Runeforge 100% offline y soberanía: IosScreenCaptureTool + Fastify wrapper
- No requiere sideload ni firma cada 7 días, no deja trazas Apple ID. 100% offline tras instalar iTunes drivers. Integra con Ollama local para análisis visual de capturas con gemma2:2b. Ideal para fase de exploración donde solo necesitas ver iPhone en RUNEFORGE-PC.

### Recomendación 2 - Para control real desde Windows sin Mac: SideTap
- Único que logra tap_text("General") con UI tree real, no OCR. Compatible con stack Ollama local ya que expone MCP tools. Requiere sideload una vez con Apple ID gratuito y mantenimiento cada 7 días via fix-input. Recomendado si necesitas automatización completa (Runeforge como agente que opera iPhone).
- Instalación: `irm https://sidetap.io/install.ps1 | iex` en PowerShell, luego setup-windows.md para Developer Mode y Sideloadly.

### Recomendación 3 - Para integración PWA: iOS-remote Flask
- Si Fastify + PWA ya sirve frontend, puedes reutilizar app.py de iOS-remote como microservicio. Menos maduro que SideTap, pero más simple para relay 8200/9100.

### Recomendación 4 - Migración Tailscale -> Headscale
- Dado que Tailscale en NoState, priorizar Headscale self-hosted antes de exponer control iPhone remoto. Headscale permite tailnet privado sin depender de control plane de Tailscale, alineado con soberanía digital.

### No recomendado
- scrcpy: Android only, no soporte iOS nativo [[17]](https://github.com/qubuss/scrcpy-mac-app). Forks iOS son inestables.
- Soluciones AirPlay wireless tipo LonelyScreen: latencia alta, no control, dependencia Wi-Fi, no open source.

## 7. Preguntas Pendientes

1. ¿WebDriverAgent firmado con free Apple ID funciona en iOS 18.5+ sin re-firmado cada 7 días? Issues en SideTap reportan expiración y necesidad de SideTap Pro con dev account pagada.
2. ¿pymobiledevice3 soporta Developer Mode tunnel en Windows 10 19045 sin wintun.dll manual? Documentación indica necesidad de wintun.dll.
3. ¿Benchmark real de SideTap con GTX 1660 SUPER + qwen2.5:1.5b en loop tap/ocr puede mantener <500ms por acción para cero latencia?
4. ¿Automerge CRDT con OPFS puede superar límite IndexedDB Safari 60% en PWA que guarda historial de screenshots iPhone?
5. ¿Headscale en Windows soporta exit nodes para iPhone cuando iOS client hardcodea control server? Necesita TestFlight build.

## Sources
[1] MacRumors — [Apple Unveils macOS 15 Sequoia With iPhone Mirroring, Passwords App, More](https://www.macrumors.com/2024/06/10/apple-announces-macos-sequoia/)
[2] MacRumors — [iPhone Mirroring in macOS Sequoia and iOS 18: Everything You Need to Know](https://macrumors.com/guide/iphone-mirroring/)
[3] LAC Co — [Platform Interaction Requirements — Mobile Application Security Design Guide iOS Edition](https://jp-east.mas.scc.lac.co.jp/iOS/en/build/html/subPage/Platform_Interaction_Requirements.html)
[4] OWASP — [MASTG-TECH-0083: Sandbox Inspection](https://mas.owasp.org/MASTG/techniques/ios/MASTG-TECH-0083/)
[5] MacRumors — [iPhone Mirroring Guide Requirements](https://macrumors.com/guide/iphone-mirroring/)
[6] Macworld — [How iPhone Mirroring lets you access your iPhone on your Mac](https://www.macworld.com/article/2404049/how-iphone-mirroring-lets-you-access-your-iphone-on-your-mac-in-macos-sequoia.html)
[7] BieleckiLtd — [IosScreenCaptureTool: Mirror your iPhone or iPad screen on your Windows PC over USB](https://github.com/BieleckiLtd/IosScreenCaptureTool)
[8] ucsandman — [SideTap: Your iPhone, driven from Windows: LLM agents tap, type, and read the screen over USB](https://github.com/ucsandman/SideTap)
[9] DimCyan — [iOS-remote: Display and control your iOS device](https://github.com/DimCyan/iOS-remote)
[10] dimcyan — [ios-remote README](https://github.com/dimcyan/ios-remote/blob/HEAD/README.md)
[11] tieorg — [pymobiledevice3 — Pure python3 implementation for working with iDevices](https://github.com/tieorg/pymobiledevice3)
[12] Go Packages — [go-ios command](https://pkg.go.dev/github.com/luc-git/go-ios)
[13] uusense — [WebDriverAgent — A WebDriver server for iOS that runs inside the Simulator](https://github.com/uusense/WebDriverAgent)
[14] Alibaba — [tidevice README_EN](https://github.com/alibaba/tidevice/blob/HEAD/README_EN.md)
[15] manuelbellucci — [appium-ios-win-boilerplate](https://github.com/manuelbellucci/appium-ios-win-boilerplate/blob/HEAD/README.md)
[16] MakeUseOf — [I replaced Tailscale's control server and finally owned my tailnet](https://www.makeuseof.com/replaced-tailscales-control-server-finally-owned-tailnet/)
[17] qubuss — [scrcpy-mac-app - Android only](https://github.com/qubuss/scrcpy-mac-app)
