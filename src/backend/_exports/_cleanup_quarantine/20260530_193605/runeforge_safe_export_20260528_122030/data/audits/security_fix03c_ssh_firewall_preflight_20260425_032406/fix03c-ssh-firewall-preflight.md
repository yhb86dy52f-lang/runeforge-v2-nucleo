# RUNEFORGE FIX03C SSH FIREWALL PREFLIGHT

Fecha: 2026-04-25T03:24:10
Modo: READ_ONLY

## Tailscale

tailscale_ip=100.111.32.10
intended_remote_address=100.64.0.0/10

## SSH listeners


LocalAddress LocalPort   PID Process Path
------------ ---------   --- ------- ----       
::                  22 10040 sshd    C:\Program…
0.0.0.0             22 10040 sshd    C:\Program…



## SSH firewall rules actuales


DisplayName      Name
-----------      ----                           
Allow SSH        AllowSSH                       
Runeforge SSH 22 {7ad679b3-5b60-4217-9340-3b32c…
OpenSSH Server   sshd                           
OpenSSH Server   {689beeb7-6c7d-4d5c-afcf-ae0b2…
OpenSSH Server   {48399a75-acfc-4dd2-a3c2-aa091…



## Eventos SSH recientes


TimeCreated               Id Message
-----------               -- -------
24/04/2026 08:48:27 p. m.  4 sshd: Accepted pas…
24/04/2026 08:48:19 p. m.  4 sshd: Failed passw…
24/04/2026 08:48:19 p. m.  4 sshd: Failed passw…
24/04/2026 03:10:25 a. m.  4 sshd: Accepted pas…
24/04/2026 03:10:14 a. m.  4 sshd: Failed passw…
24/04/2026 03:10:14 a. m.  4 sshd: Failed passw…
24/04/2026 03:08:33 a. m.  4 sshd: Accepted pas…
24/04/2026 03:08:23 a. m.  4 sshd: Failed passw…
24/04/2026 03:08:23 a. m.  4 sshd: Failed passw…
24/04/2026 03:00:42 a. m.  4 sshd: Accepted pas…



## Propuesta de FIX03C

- Crear regla nueva: Runeforge SSH Tailscale Only
- Permitir TCP 22 solo desde 100.64.0.0/10
- Deshabilitar reglas SSH duplicadas con RemoteAddress=Any
- NO tocar sshd_config
- NO reiniciar sshd
- Crear rollback

## Nota

No se modificó nada.
