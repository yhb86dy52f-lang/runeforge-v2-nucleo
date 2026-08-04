# RUNEFORGE FIX03E-B TERMIUS FAILURE REPORT

Fecha: 2026-04-25T03:50:37
Modo: READ_ONLY

## Conteo eventos OpenSSH últimos 20 min

- accepted_publickey=0
- accepted_password=0
- failed_publickey_or_permission=0
- failed_password=0
- reset_or_closed=0

## sshd_config relevante

- Port 22
- PubkeyAuthentication yes
- PasswordAuthentication yes
- AllowUsers nesth
- LogLevel INFO
- Match Group administrators
- AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys


## Authorized keys metadata


Path   : C:\ProgramData\ssh\administrators_authorized_keys
Exists : True
Length : 198
Owner  : BUILTIN\Administradores
Access : NT AUTHORITY\SYSTEM:FullControl:Inherited=False | BUILTIN\Administradores:FullControl:Inherited=False

Path   : C:\Users\nesth\.ssh\authorized_keys
Exists : True
Length : 198
Owner  : BUILTIN\Administradores
Access : NT AUTHORITY\SYSTEM:FullControl:Inherited=False | BUILTIN\Administradores:FullControl:Inherited=False | DESKTOP-NDFE0B0\nesth:FullControl:Inherited=False



## Firewall SSH Tailscale Only


DisplayName   : Runeforge SSH Tailscale Only
Enabled       : True
LocalPort     : 22
Protocol      : TCP
RemoteAddress : 100.64.0.0/255.192.0.0
Program       : C:\Program Files\OpenSSH-Win64\sshd.exe



## Eventos recientes



## Nota

No se modificó nada.
No se imprimieron claves completas.
