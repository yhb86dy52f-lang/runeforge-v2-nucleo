# RUNEFORGE FIX03D SSH KEY AUTH PREFLIGHT

Fecha: 2026-04-25T03:39:25
Modo: READ_ONLY

## Servicio SSH


Name        : sshd
DisplayName : OpenSSH SSH Server
Status      : Running
StartType   : Automatic



## Tailscale

tailscale_ip=100.111.32.10

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



## Authorized keys — metadata sin claves completas

### Usuario


Path          : C:\Users\nesth\.ssh\authorized_keys
Exists        : True
Length        : 198
LastWriteTime : 2026-04-18T00:01:15
Owner         : BUILTIN\Administradores



### Administradores


Path          : C:\ProgramData\ssh\administrators_authorized_keys
Exists        : True
Length        : 198
LastWriteTime : 2026-04-18T00:01:15
Owner         : BUILTIN\Administradores



## Fingerprints detectados

### Usuario authorized_keys

- [OK] 256 SHA256:xgm3zviu0cns+Mtd3Zt4WADmLO5BGoPORWbxArCfzRo no comment (ED25519)
- [OK] 256 SHA256:3DIhHKONBPtsnqFTYNPcVE2rwL8e+D+Oer1w5ESK7z4 no comment (ED25519)


### Administrators authorized_keys

- [OK] 256 SHA256:xgm3zviu0cns+Mtd3Zt4WADmLO5BGoPORWbxArCfzRo no comment (ED25519)
- [OK] 256 SHA256:3DIhHKONBPtsnqFTYNPcVE2rwL8e+D+Oer1w5ESK7z4 no comment (ED25519)


## Llaves públicas locales en perfil

- No se detectaron .pub locales en C:\Users\nesth\.ssh

## Checks

- PasswordAuthentication enabled: True
- PubkeyAuthentication enabled: True
- AllowUsers nesth: True
- Match Group administrators: True
- administrators_authorized_keys configurado: True
- total fingerprints autorizados: 4
- readiness: KEY_AUTH_POSSIBLE_TEST_REQUIRED_FROM_TERMIUS
- can disable password later: NO_AUN_TEST_TERMIUS_REQUIRED

## Nota

No se imprimieron claves completas.
No se modificó sshd_config.
No se reinició SSH.
No se modificó firewall.
No se tocó Tailscale.
