[RUNEFORGE_MEMORY_CLAUSE_2026-04-25_SECURITY_FIX03F]

Fecha: 2026-04-25
Estado: FIX03F SSH PasswordAuthentication desactivado y validado

Se completó el hardening de SSH para Runeforge/PC Windows.

Estado validado:
- SSH sigue activo.
- OpenSSH Server está Running / Automatic.
- Firewall SSH quedó restringido a Tailscale con regla:
  Runeforge SSH Tailscale Only
- RemoteAddress:
  100.64.0.0/255.192.0.0
- PubkeyAuthentication yes
- PasswordAuthentication no
- AllowUsers nesth

Llave validada:
RUNEFORGE_TERMIUS_20260425
Fingerprint:
SHA256:mYH6LymoMYula8qdvMIsFJSWXdTybKQMD3EEy4T/blQ

Validación final:
- accepted_publickey_last_15m=3
- accepted_password_last_15m=0
- failed_password_last_15m=0

Conclusión:
Termius entra correctamente por llave pública vía Tailscale.
El acceso SSH por contraseña quedó desactivado.

Rollback disponible:
C:\RUNEFOGE_PRO\runeforge\data\audits\security_fix03f_disable_ssh_password_20260425_041611\rollback-fix03f-ssh-password.ps1

No se tocó backend.
No se tocó firewall en FIX03F.
No se tocó Tailscale.
