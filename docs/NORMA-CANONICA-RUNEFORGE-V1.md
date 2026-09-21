# NORMA CANÓNICA RUNEFORGE v1.0 - IRREFUTABLE E INAMOVIBLE
# Fecha de canonización: 2026-09-20 13:03:19 - Build exitoso nexus-lab.exe 2.94 MB
# Hash del artefacto: nexus-lab v1.0.0 - 429 crates - 54m 53s - Rust 1.98.1
# Estado: CANONIZADO - No se modifica sin RFC y tag vX.Y.Z

## 0. PRINCIPIOS IRREFUTABLES

1. **-NoProfile siempre**: Todo bootstrap se ejecuta con `pwsh -NoProfile -ExecutionPolicy Bypass -File`
   Razón: Tu prompt RUNEFORGE custom con Get-Process rompe mkdir, Copy-Item, $env:.
   
2. **ErrorActionPreference = Continue**: Nunca Stop en scripts con npm/cargo nativos.
   Stop convierte stderr warn en RemoteException.

3. **cmd /c para todo nativo**: npm, cargo, rustc se invocan vía `cmd /c "... >nul 2>&1"` para aislar stderr.

4. **HTTP/1.1 forzado para Rust**: schannel en Windows + HTTP/2 = SEC_E_DECRYPT_FAILURE 0x80090330

## 1. NORMA NODE.JS / TAURI (LMU-HMI + NEXUS LAB)

### 1.1 Entorno canónico
```
NODE_VER = 20.18.0 portable (no global)
$env:NODE_OPTIONS = "--openssl-legacy-provider --max-old-space-size=4096"
$env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
$env:OPENSSL_CONF = ""
RUST = 1.98.1
```

### 1.2 Limpieza canónica (antes de cada build)
```powershell
Get-Process node,npm,npx,esbuild,vite -ErrorAction SilentlyContinue | Stop-Process -Force
takeown /F node_modules /R /D Y >nul
attrib -R -H -S node_modules\*.* /S /D >nul
rmdir /s /q node_modules >nul 2>&1
Remove-Item node_modules -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item package-lock.json,yarn.lock,Cargo.lock -Force -ErrorAction SilentlyContinue
```

### 1.3 Cache npm canónica
```powershell
# NUNCA: & $npm cache clean --force 2>&1 | Out-Null  -> Rompe con Stop
# SIEMPRE:
cmd /c "npm cache clean --force --loglevel=error >nul 2>&1"
cmd /c "npm cache verify --loglevel=error >nul 2>&1"
```

### 1.4 Instalación npm con cascada de registros
```
Intento 1: https://registry.npmjs.org/ (HTTPS + OpenSSL legacy)
Intento 2: http://registry.npmjs.org/ (HTTP sin TLS, bypass total)
Intento 3: https://registry.npmmirror.com/ (espejo China)
Cada intento: limpia node_modules + rmdir nativo
Al final: restaurar a https://registry.npmjs.org/
```

## 2. NORMA CARGO / RUST (NEXUS LAB - Tauri)

### 2.1 Config global canónica: C:\Users\%USERNAME%\.cargo\config.toml
```toml
[http]
multiplexing = false  # HTTP/1.1 forzado, evita SEC_E_DECRYPT_FAILURE
timeout = 180
low-speed-limit = 5

[net]
retry = 10
git-fetch-with-cli = true

[registries.crates-io]
protocol = "sparse"  # No git index, más estable
```

### 2.2 Variables de sesión canónicas
```powershell
$env:CARGO_HTTP_MULTIPLEXING = "false"
$env:CARGO_NET_RETRY = "10"
$env:CARGO_HTTP_TIMEOUT = "180"
$env:CARGO_REGISTRIES_CRATES_IO_PROTOCOL = "sparse"
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"
```

### 2.3 Build con fallback automático
```powershell
for ($i=1; $i -le 2; $i++) {
  if ($i -eq 2) {
    # Espejo USTC solo en 2do intento
    @'
[http]
multiplexing = false
timeout = 180
[net]
retry = 10
git-fetch-with-cli = true
[source.crates-io]
replace-with = "ustc"
[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
'@ | Set-Content "$env:USERPROFILE\.cargo\config.toml" -Encoding UTF8
  }
  cargo build --release
  if ($LASTEXITCODE -eq 0 -and (Test-Path "target\release\nexus-lab.exe")) { break }
}
# Restaurar sin espejo al final
```

### 2.4 Artefacto canónico
```
target\release\nexus-lab.exe = 2.94 MB (release, optimized)
429 crates locked
Tiempo: 54m 53s primera vez, 20s incremental
Warning permitido: linker stdout Creating library...dll.lib (1 warning normal)
```

## 3. NORMA DE ESCALAMIENTO

Para escalar de 1 lab (nexus-lab) a N labs (lmu-hmi, flota-kw-os, runeforge):

1. **Template**: Copiar `C:\RUNEFORGE_V2_CORE\apps\nexus-lab` como base
2. **Cambiar solo**: `tauri.conf.json` productName + identifier + `Cargo.toml` name
3. **Mantener idéntico**: `config.toml` canónico, `Invoke-FullCleanup`, cascada npm, env vars
4. **Build**: Usar `Invoke-CanonicalBuild.ps1 -AppName <nombre>` (script único)

## 4. VERIFICACIÓN IRREFUTABLE

Build es canónico si:
- [ ] `nexus-lab.exe` existe y pesa 2.5-3.5 MB
- [ ] `cargo build --release` termina con `Finished release profile`
- [ ] No hay `SEC_E_DECRYPT_FAILURE` ni `ERR_SSL_CIPHER_OPERATION_FAILED`
- [ ] `npm run build` genera `dist\index.html`

## 5. INAMOVILIDAD

Este documento se versiona con tag git:
```
git tag -a v1.0-canon -m "Norma canónica 2026-09-20 13:03:19 - nexus-lab.exe 2.94MB"
git push origin v1.0-canon
```

Cualquier cambio requiere RFC en `EL_ABISMO/01_MEMORIAS/` y nuevo tag.

---
Firmado: RUNEFORGE V2.6.2 - PM2 ONLINE - 2026-09-20 13:03:19
