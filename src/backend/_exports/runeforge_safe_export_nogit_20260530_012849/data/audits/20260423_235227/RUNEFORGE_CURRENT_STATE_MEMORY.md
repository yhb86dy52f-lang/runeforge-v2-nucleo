# RUNEFORGE CURRENT STATE MEMORY

## METADATA
fecha: 20260423_235227
modo: AUDIT_ONLY
raiz_canonica: C:\RUNEFOGE_PRO\runeforge
backend: C:\RUNEFOGE_PRO\runeforge\app
usuario_windows: DESKTOP-NDFE0B0\nesth
admin: True

## ESTADO DE ESTRUCTURA
raiz_existe: True
backend_existe: True
ruta_no_canonica_detectada: True

## REGLAS OPERATIVAS
- Backend primero, UI después.
- No renombrar raíz activa sin mapa de dependencias.
- No abrir puertos fuera de Tailscale sin justificación.
- No excluir árboles completos de Defender.
- Secretos en .env, nunca en memoria global.
- Flujo obligatorio: INPUT → ROUTER → SKILL → ACTION → TRACE → RESPONSE.

## RIESGOS
| severity | category | issue | evidence | action |
| --- | --- | --- | --- | --- |
| HIGH | rutas | Existe ruta no canónica C:\RUNEFORGE_PRO | files=1; dirs=0; sizeMB=0 | No usar como raíz. Auditar contenido y migrar a archive si no contiene estado activo. |
| HIGH | seguridad | Exclusión de Defender relacionada con Runeforge/Abismo/scripts | C:\RUNEFORGE_PRO | Revisar y remover si no es estrictamente necesaria. No excluir árboles completos. |
| HIGH | seguridad | Exclusión de Defender relacionada con Runeforge/Abismo/scripts | C:\scripts | Revisar y remover si no es estrictamente necesaria. No excluir árboles completos. |
| HIGH | seguridad | Exclusión de Defender relacionada con Runeforge/Abismo/scripts | C:\Users\nesth\Documents\EL_ABISMO | Revisar y remover si no es estrictamente necesaria. No excluir árboles completos. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | svchost:135 PID=984 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | svchost:135 PID=984 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | System:445 PID=4 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5001 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5002 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5003 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5004 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5005 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5006 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5007 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5008 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5009 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5010 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5011 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5012 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5013 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5014 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5015 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5016 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5017 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5018 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5019 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5020 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:5021 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:5021 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5022 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5023 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5024 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5025 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5026 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5027 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5028 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5029 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5030 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5031 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5032 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5033 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5034 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5035 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5036 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5037 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5039 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5040 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5041 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5042 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5043 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5044 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5045 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5046 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5047 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5048 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5049 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5050 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5051 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5052 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5054 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5055 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5056 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5057 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5058 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5059 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5060 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5061 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5062 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5063 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5064 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5065 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5066 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5067 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5068 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5069 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5070 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5071 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5072 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5073 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5074 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5075 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5076 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5077 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5078 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5079 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5080 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5081 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5083 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5085 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5086 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5087 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5088 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5089 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5090 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5091 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5092 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5093 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5094 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5095 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5096 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5097 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5098 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5099 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5100 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5101 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5102 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5103 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5105 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5106 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5107 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5108 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5109 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5110 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5111 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5112 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5113 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5114 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5115 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5116 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5117 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5118 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5119 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5120 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5122 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5123 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5124 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5126 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5127 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5128 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5129 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5130 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5131 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5132 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5133 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5134 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5135 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5136 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5137 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5139 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5140 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5141 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5142 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5143 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5144 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5145 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5146 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5147 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5148 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5149 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5150 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5151 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5152 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5153 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5154 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5155 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5156 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5157 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5159 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5160 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5161 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5162 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5163 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5164 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5165 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5166 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5167 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5168 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5169 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5171 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5172 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5173 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5174 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5176 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5177 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5178 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5179 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5180 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5181 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5182 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5184 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5185 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5186 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5187 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5188 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5191 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5192 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5193 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5194 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5195 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5197 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5199 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5200 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5201 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5202 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5203 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5204 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5205 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5206 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5207 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5208 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5209 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5210 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5211 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5212 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5213 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5214 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5215 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5216 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5217 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5218 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5219 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5220 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5221 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5222 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5223 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5225 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5226 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5228 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5229 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5231 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5232 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5233 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5234 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5235 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5236 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5237 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5238 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5239 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5240 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5241 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5242 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5243 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5244 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5245 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5246 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5247 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5248 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5249 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5250 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5251 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5253 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5255 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5256 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5257 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5258 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5259 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5261 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:5262 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | System:5357 PID=4 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | System:5985 PID=4 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:7000 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:7000 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:7100 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:7100 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | svchost:7680 PID=3448 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:8008 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:8009 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | java:8082 PID=4608 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:8100 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | AirServer:8100 PID=8216 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | System:47001 PID=4 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| HIGH | red | Puerto escuchando en todas las interfaces | sunshine:47984 PID=3724 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| HIGH | red | Puerto escuchando en todas las interfaces | sunshine:47989 PID=3724 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| HIGH | red | Puerto escuchando en todas las interfaces | sunshine:47990 PID=3724 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| HIGH | red | Puerto escuchando en todas las interfaces | sunshine:48010 PID=3724 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | lsass:49664 PID=760 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | lsass:49664 PID=760 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | wininit:49665 PID=676 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | wininit:49665 PID=676 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | svchost:49666 PID=1148 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | svchost:49666 PID=1148 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | svchost:49667 PID=1572 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | svchost:49667 PID=1572 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | spoolsv:49668 PID=4092 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | spoolsv:49668 PID=4092 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | services:49679 PID=748 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| MEDIUM | red | Puerto escuchando en todas las interfaces | services:49679 PID=748 | Confirmar si debe estar en 0.0.0.0/::. Preferir localhost o Tailscale. |
| HIGH | secretos | Se detectaron posibles secretos o variables sensibles en archivos | 217 indicadores | Mover secretos a .env local, rotar claves expuestas y evitar memoria global. |
| LOW | windows | Print Spooler activo | Spooler=Running | Si no imprimes desde esta PC, considerar deshabilitar en fase de hardening. |

## PLAN SIGUIENTE
1. Revisar udit-summary.txt.
2. Si hay ruta no canónica con datos, ejecutar fase de migración controlada.
3. Si hay secretos, rotar y limpiar memoria.
4. Si hay puertos en 0.0.0.0, restringir a localhost/Tailscale.
5. Solo después conectar RF Lab al backend.
