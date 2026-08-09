# RF_WHATSAPP_RELAY_V1

Estado: SCAFFOLD_DRYRUN

Rol: canal/adaptador WhatsApp. No es nucleo Runeforge.

Flujo: WHATSAPP_WEBHOOK -> RELAY -> ROUTER -> SKILL -> ACTION -> TRACE -> RESPONSE

Permitido Fase 1: help, status_readonly, chat_local_ai, trace_event.

Bloqueado Fase 1: shell, powershell, filesystem_write, firewall, secrets, hardware_control, send_real_without_confirm.

Siguiente: RF_WHATSAPP_WEBHOOK_ECHO_V1
