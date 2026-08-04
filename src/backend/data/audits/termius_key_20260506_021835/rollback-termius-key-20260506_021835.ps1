Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Copy-Item -LiteralPath 'C:\RUNEFOGE_PRO\runeforge\data\audits\termius_key_20260506_021835\administrators_authorized_keys.20260506_021835.bak' -Destination 'C:\ProgramData\ssh\administrators_authorized_keys' -Force
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /inheritance:r | Out-Null
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' | Out-Null
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /setowner '*S-1-5-32-544' | Out-Null
Restart-Service sshd -Force
Write-Host '[OK] Rollback Termius key aplicado.'
