# RUNEFORGE FIX03B SSH READONLY REPORT

Fecha: 2026-04-25T03:22:22
Modo: READ_ONLY

## Servicio SSH


Name        : sshd
DisplayName : OpenSSH SSH Server
Status      : Running
StartType   : Automatic



## sshd_config resumen

- Port 22
- PubkeyAuthentication yes
- PasswordAuthentication yes
- AllowUsers nesth
- Match Group administrators
- AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys


## Listeners puerto 22


LocalAddress LocalPort   PID Process Path
------------ ---------   --- ------- ----       
::                  22 10040 sshd    C:\Program…
0.0.0.0             22 10040 sshd    C:\Program…



## Reglas firewall SSH


DisplayName      Name
-----------      ----                           
Allow SSH        AllowSSH                       
Runeforge SSH 22 {7ad679b3-5b60-4217-9340-3b32c…
OpenSSH Server   sshd                           
OpenSSH Server   {689beeb7-6c7d-4d5c-afcf-ae0b2…
OpenSSH Server   {48399a75-acfc-4dd2-a3c2-aa091…



## Tailscale

IP:
100.111.32.10

## Nota

No se modificó sshd_config.
No se reinició SSH.
No se modificó firewall.
No se tocó Tailscale.
