---
sello: Forneus
sello_numero: 30
origen: docs
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus]
fecha_forja: 2026-09-28
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# ESTATUS FINAL VERDE - 2026-08-15_14-16-58 - HEADSCALE UP + TAILNET UNIFICADO

=== PWSH ===
7.6.3 Core OK >=7.4.0

=== DOCKER ENGINE ===
Docker version 29.7.2, build a7dcaa6
CONTAINER ID IMAGE STATUS PORTS
363694fd1979 headscale/headscale:v0.25.1 Up 3 minutes 0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp, 0.0.0.0:3478->3478/udp, [::]:3478->3478/udp, 0.0.0.0:9090->9090/tcp, [::]:9090->9090/tcp
PORT 8080 OCUPADO PID 1980 - HEADSCALE LISTENING

=== TAILSCALE TAILNET forgerrune@gmail.com ===
100.83.105.117  desktop-ndfe0b0  forgerrune@  windows  -  
100.100.167.48  runeforge        forgerrune@  linux    -  

=== SSH RUNEFORGE TEST ===
ssh: connect to host 100.111.32.10 port 22: Connection timed out


=== HEADSCALE LOGS ===
2026-08-15T19:03:09Z INF No private key file at path, creating... path=
2026-08-15T19:03:09Z FTL home/runner/work/headscale/headscale/cmd/headscale/cli/serve.go:24 > Error initializing error="failed to read or create DERP server private key: failed to save private key to disk at path \"\": open : no such file or directory"
2026-08-15T19:03:16Z INF Opening database database=sqlite3 path=/etc/headscale/data/db.sqlite
2026-08-15T19:03:16Z INF No private key file at path, creating... path=
2026-08-15T19:03:16Z FTL home/runner/work/headscale/headscale/cmd/headscale/cli/serve.go:24 > Error initializing error="failed to read or create DERP server private key: failed to save private key to disk at path \"\": open : no such file or directory"
2026-08-15T19:03:29Z INF Opening database database=sqlite3 path=/etc/headscale/data/db.sqlite
2026-08-15T19:03:29Z INF No private key file at path, creating... path=
2026-08-15T19:03:29Z FTL home/runner/work/headscale/headscale/cmd/headscale/cli/serve.go:24 > Error initializing error="failed to read or create DERP server private key: failed to save private key to disk at path \"\": open : no such file or directory"
2026-08-15T20:13:26Z INF No private key file at path, creating... path=/etc/headscale/data/noise_private.key
2026-08-15T20:13:26Z INF Opening database database=sqlite3 path=/etc/headscale/data/db.sqlite
2026-08-15T20:13:29Z INF No private key file at path, creating... path=/etc/headscale/data/derp_server_private.key
2026-08-15T20:13:29Z INF home/runner/work/headscale/headscale/hscontrol/app.go:570 > Clients with a lower minimum version will be rejected minimum_version=v1.62.0
2026-08-15T20:13:29Z INF home/runner/work/headscale/headscale/hscontrol/derp/server/derp_server.go:106 > DERP region: {RegionID:999 RegionCode:runeforge RegionName:Runeforge DERP Latitude:0 Longitude:0 Avoid:false Nodes:[0xc000604090]}
2026-08-15T20:13:29Z INF home/runner/work/headscale/headscale/hscontrol/derp/server/derp_server.go:107 > DERP Nodes[0]: &{Name:999 RegionID:999 HostName:192.168.100.12 CertName: IPv4: IPv6: STUNPort:3478 STUNOnly:false DERPPort:8080 InsecureForTests:false STUNTestIP: CanPort80:false}
2026-08-15T20:13:29Z INF STUN server started at [::]:3478
2026-08-15T20:13:29Z INF Enabling remote gRPC at 0.0.0.0:50443
2026-08-15T20:13:29Z WRN gRPC is running without security
2026-08-15T20:13:29Z INF listening and serving gRPC on: 0.0.0.0:50443
2026-08-15T20:13:29Z INF listening and serving HTTP on: 0.0.0.0:8080
2026-08-15T20:13:29Z INF listening and serving debug and metrics on: 0.0.0.0:9090

=== CIERRE CONTROLADO ===
Log: C:\RUNEFORGE_V2_CORE\docs\ESTATUS_FINAL_VERDE_2026-08-15_14-16-58.md
PWA http://192.168.100.4:3100/forge -> https://runeforge.tail12b297.ts.net via tailscale serve
