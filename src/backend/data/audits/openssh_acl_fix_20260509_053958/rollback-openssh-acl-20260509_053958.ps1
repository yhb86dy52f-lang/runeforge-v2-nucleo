Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Stop-Service sshd -Force -ErrorAction SilentlyContinue
Copy-Item -LiteralPath 'C:\RUNEFOGE_PRO\runeforge\data\audits\openssh_acl_fix_20260509_053958\sshd_config_20260509_053958.bak' -Destination 'C:\ProgramData\ssh\sshd_config' -Force
Copy-Item -LiteralPath 'C:\RUNEFOGE_PRO\runeforge\data\audits\openssh_acl_fix_20260509_053958\administrators_authorized_keys_20260509_053958.bak' -Destination 'C:\ProgramData\ssh\administrators_authorized_keys' -Force
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /inheritance:r | Out-Null
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /grant:r '*S-1-5-18:F' '*S-1-5-32-544:F' | Out-Null
icacls 'C:\ProgramData\ssh\administrators_authorized_keys' /setowner '*S-1-5-32-544' | Out-Null
Start-Service sshd
Write-Host '[OK] Rollback ACL OpenSSH aplicado.'
