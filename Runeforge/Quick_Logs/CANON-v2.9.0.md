---
sello: Forneus
sello_numero: 30
origen: docs
tipo: Quick_Logs
up: "[[Runeforge/MOCs/MOC-Quick_Logs]]"
tags: [Runegea, QuickLog]
fecha_forja: 2026-09-28
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-Quick_Logs]]

# CANON v2.9.0 - Optimizacion de compilacion

**Fecha**: 2026-09-26
**Estado**: Validado en produccion

## Hallazgo

El macro `tauri::generate_context!()` genera ~500 KB de codigo Rust
autogenerado (HTML embebido + CSP + config). Compilar ese codigo con
opt-level=1 consume 3-4 minutos por app.

## Fix aplicado

Inyectar `[profile.release.package.<app>] opt-level = 0` en el Cargo.toml
de cada app. Solo afecta al crate de la app; las 426 dependencias siguen
optimizadas con opt-level=1.

## Resultados medidos

| Config                   | Tiempo  | Tamano  |
|--------------------------|---------|---------|
| Baseline (opt=1 todo)    | 259 s   | 3.89 MB |
| opt-level=0 solo app     | 85 s    | 6.84 MB |

Mejora: 3.06x mas rapido.
Trade-off: +76% tamano (aceptable para apps de escritorio).

## Implementacion en Nexus-Forge.ps1

Linea 88 (despues del Set-Content del Cargo.toml):

    Add-Content "$srcTauri\Cargo.toml" -Value "`n`n[profile.release.package.$Name]`nopt-level = 0`n" -Encoding UTF8

## Proximos experimentos (v3.0)

- Probar opt-level = "s" (size) en lugar de 0
- Considerar desactivar compression en tauri (brotli en compile time)
- Workspace Cargo unificado (elimina resolucion de 426 crates por app)
