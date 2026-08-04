# RUNEFORGE - Auditoría de Infraestructura y Seguridad

## 1. Estado
- Fecha: 20260423_235227
- Modo: AUDIT_ONLY_NO_RENAME_NO_FIREWALL_CHANGE
- Raíz canónica: $CanonicalRoot
- Backend: $backendPath
- Usuario: DESKTOP-NDFE0B0\nesth
- Admin: True

## 2. Herramientas
| command | found | source | version |
| --- | --- | --- | --- |
| pwsh | True | C:\Program Files\PowerShell\7\pwsh.exe | 7.6.0.0 |
| node | True | C:\Program Files\nodejs\node.exe | v20.11.1 |
| npm | True | C:\Program Files\nodejs\npm.cmd | 10.2.4 |
| pm2 | True | C:\Users\nesth\AppData\Roaming\npm\pm2.ps1 | [PM2] Spawning PM2 daemon with pm2_home=C:\Users\nesth\.pm2 [PM2] PM2 Successfully daemonized 6.0.14 |
| git | True | C:\Program Files\Git\cmd\git.exe | git version 2.44.0.windows.1 |
| tailscale | True | C:\Program Files\Tailscale\tailscale.exe | 1.96.3   tailscale commit: 3ffddb1344a2ca023f3f6998b915351eae3d5d67   long version: 1.96.3-t3ffddb134-g460d8764a   other commit: 460d8764aa91f4859f44e9f7f4dcb48edc1fb451   go version: go1.26.1 |
| AutoHotkey64 | False |  |  |
| AutoHotkey | False |  |  |

## 3. Servicios críticos
| name | exists | status | startType |
| --- | --- | --- | --- |
| Tailscale | True | Running | Auto |
| WinDefend | True | Running | Auto |
| mpssvc | True | Running | Auto |
| sshd | True | Stopped | Manual |
| ssh-agent | True | Stopped | Manual |
| Spooler | True | Running | Auto |
| RemoteRegistry | True | Stopped | Disabled |
| TermService | True | Stopped | Manual |

## 4. Puertos escuchando
| protocol | localAddress | localPort | processName | owningProcess | exposure |
| --- | --- | --- | --- | --- | --- |
| TCP | 0.0.0.0 | 135 | svchost | 984 | ALL_INTERFACES |
| TCP | :: | 135 | svchost | 984 | ALL_INTERFACES |
| TCP | 192.168.100.3 | 139 | System | 4 | SPECIFIC_INTERFACE |
| TCP | 192.168.137.1 | 139 | System | 4 | SPECIFIC_INTERFACE |
| TCP | :: | 445 | System | 4 | ALL_INTERFACES |
| TCP | :: | 5001 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5002 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5003 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5004 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5005 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5006 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5007 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5008 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5009 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5010 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5011 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5012 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5013 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5014 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5015 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5016 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5017 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5018 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5019 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5020 | java | 4608 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 5021 | AirServer | 8216 | ALL_INTERFACES |
| TCP | :: | 5021 | AirServer | 8216 | ALL_INTERFACES |
| TCP | :: | 5022 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5023 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5024 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5025 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5026 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5027 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5028 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5029 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5030 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5031 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5032 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5033 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5034 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5035 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5036 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5037 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5039 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5040 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5041 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5042 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5043 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5044 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5045 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5046 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5047 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5048 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5049 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5050 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5051 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5052 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5054 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5055 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5056 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5057 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5058 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5059 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5060 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5061 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5062 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5063 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5064 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5065 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5066 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5067 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5068 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5069 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5070 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5071 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5072 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5073 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5074 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5075 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5076 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5077 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5078 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5079 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5080 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5081 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5083 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5085 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5086 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5087 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5088 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5089 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5090 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5091 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5092 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5093 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5094 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5095 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5096 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5097 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5098 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5099 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5100 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5101 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5102 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5103 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5105 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5106 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5107 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5108 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5109 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5110 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5111 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5112 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5113 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5114 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5115 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5116 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5117 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5118 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5119 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5120 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5122 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5123 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5124 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5126 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5127 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5128 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5129 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5130 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5131 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5132 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5133 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5134 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5135 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5136 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5137 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5139 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5140 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5141 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5142 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5143 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5144 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5145 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5146 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5147 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5148 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5149 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5150 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5151 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5152 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5153 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5154 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5155 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5156 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5157 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5159 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5160 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5161 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5162 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5163 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5164 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5165 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5166 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5167 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5168 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5169 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5171 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5172 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5173 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5174 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5176 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5177 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5178 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5179 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5180 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5181 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5182 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5184 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5185 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5186 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5187 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5188 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5191 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5192 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5193 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5194 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5195 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5197 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5199 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5200 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5201 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5202 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5203 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5204 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5205 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5206 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5207 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5208 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5209 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5210 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5211 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5212 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5213 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5214 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5215 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5216 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5217 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5218 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5219 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5220 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5221 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5222 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5223 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5225 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5226 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5228 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5229 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5231 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5232 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5233 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5234 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5235 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5236 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5237 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5238 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5239 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5240 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5241 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5242 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5243 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5244 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5245 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5246 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5247 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5248 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5249 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5250 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5251 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5253 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5255 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5256 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5257 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5258 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5259 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5261 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5262 | java | 4608 | ALL_INTERFACES |
| TCP | :: | 5357 | System | 4 | ALL_INTERFACES |
| TCP | :: | 5985 | System | 4 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 7000 | AirServer | 8216 | ALL_INTERFACES |
| TCP | :: | 7000 | AirServer | 8216 | ALL_INTERFACES |
| TCP | :: | 7100 | AirServer | 8216 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 7100 | AirServer | 8216 | ALL_INTERFACES |
| TCP | :: | 7680 | svchost | 3448 | ALL_INTERFACES |
| TCP | :: | 8008 | AirServer | 8216 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 8009 | AirServer | 8216 | ALL_INTERFACES |
| TCP | :: | 8082 | java | 4608 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 8100 | AirServer | 8216 | ALL_INTERFACES |
| TCP | :: | 8100 | AirServer | 8216 | ALL_INTERFACES |
| TCP | 127.0.0.1 | 9180 | lghub_updater | 4368 | LOOPBACK |
| TCP | 127.0.0.1 | 12100 | SmartPSSLiteDaemon | 9684 | LOOPBACK |
| TCP | 127.0.0.1 | 23420 | WebSocketServer23420 | 12276 | LOOPBACK |
| TCP | 100.111.32.10 | 39091 | tailscaled | 6956 | SPECIFIC_INTERFACE |
| TCP | fd7a:115c:a1e0::f3b:200a | 40671 | tailscaled | 6956 | SPECIFIC_INTERFACE |
| TCP | ::1 | 42050 | OneDrive.Sync.Service | 10940 | LOOPBACK |
| TCP | :: | 47001 | System | 4 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 47984 | sunshine | 3724 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 47989 | sunshine | 3724 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 47990 | sunshine | 3724 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 48010 | sunshine | 3724 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 49664 | lsass | 760 | ALL_INTERFACES |
| TCP | :: | 49664 | lsass | 760 | ALL_INTERFACES |
| TCP | :: | 49665 | wininit | 676 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 49665 | wininit | 676 | ALL_INTERFACES |
| TCP | :: | 49666 | svchost | 1148 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 49666 | svchost | 1148 | ALL_INTERFACES |
| TCP | :: | 49667 | svchost | 1572 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 49667 | svchost | 1572 | ALL_INTERFACES |
| TCP | :: | 49668 | spoolsv | 4092 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 49668 | spoolsv | 4092 | ALL_INTERFACES |
| TCP | 0.0.0.0 | 49679 | services | 748 | ALL_INTERFACES |
| TCP | :: | 49679 | services | 748 | ALL_INTERFACES |
| TCP | 127.0.0.1 | 49763 | WebSocketServer23420 | 12276 | LOOPBACK |
| TCP | 127.0.0.1 | 61001 | AirServer | 8216 | LOOPBACK |

## 5. Riesgos detectados
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

## 6. Indicadores de secretos
> No se imprimen valores sensibles. Solo archivo/patrón.

| severity | file | pattern | note |
| --- | --- | --- | --- |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\.env | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\.env | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\.env | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\retro\_downloads\PPSSPPWindowsARM64\assets\debugger\static\js\main.fe87e942.js | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\src\adapters\whatsapp\whatsapp.webhook.routes.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\src\config\env.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\src\config\env.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\src\config\env.js | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\vite.config.js | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\vite.config.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_release-notifier.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-changelog.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-docs.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-flathub-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-homebrew-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-pacman-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-winget-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-archlinux.yml | passwd\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-bundle.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-copr.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-copr.yml | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-homebrew.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-linux.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-macos.yml | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-windows.yml | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\localize.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\update-pages.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\RUNEFOGE_PRO\runeforge\app\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\data (1)\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab (1)\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab (1)\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab (1)\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab (2)\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab (2)\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\lab (2)\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\retro\_downloads\PPSSPPWindowsARM64\assets\debugger\static\js\main.fe87e942.js | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\runeforge-mvp\src\adapters\whatsapp\whatsapp.webhook.routes.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\runeforge-mvp\src\config\env.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\runeforge-mvp\src\config\env.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\runeforge-mvp\src\config\env.js | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\vite.config.js | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\vite.config.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_release-notifier.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-changelog.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-docs.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-flathub-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-homebrew-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-pacman-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-winget-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-archlinux.yml | passwd\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-bundle.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-copr.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-copr.yml | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-homebrew.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-linux.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-macos.yml | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-windows.yml | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\localize.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\update-pages.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\.env | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\.env | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\src\env.ts | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\src\env.ts | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\src\relay\whatsapp\router.ts | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\00_INBOX\OpenLayers.js | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\02_AT\Skypatrol.txt | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\cuenta gps wox.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\puttydoc.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 ARGENTINA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 AVANTEL WIALON ID.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 ID WIALON.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 USA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 WIALON ID AVANTEL USA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\data (1)\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\02_AT\Skypatrol.txt | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\cuenta gps wox.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\puttydoc.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 ARGENTINA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 AVANTEL WIALON ID.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 ID WIALON.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 USA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 WIALON ID AVANTEL USA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\data (1)\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\02_AT\Skypatrol.txt | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\cuenta gps wox.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\puttydoc.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 ARGENTINA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 AVANTEL WIALON ID.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 ID WIALON.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 USA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 WIALON ID AVANTEL USA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\data (1)\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (1)\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 ARGENTINA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 ID WIALON.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\lab (2)\data\TT8750 WIALON ID AVANTEL USA.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\02_AT\Skypatrol.txt | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\cuenta gps wox.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\puttydoc.txt | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 ARGENTINA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 AVANTEL WIALON ID.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 ID WIALON.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 USA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\DRIVE ME IPHONE\TODO\CCTV\GEMINI\LMU4350\05_SMS_Y_AT\03_LOGS\TT8750 WIALON ID AVANTEL USA.TXT | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\essential_only\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\docs\designs\_15_to_22\2026-03-25-zod-to-types-generator-phase-4-v2.md | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\include\DATA_SCHEMA.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\essential_only\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\docs\designs\_15_to_22\2026-03-25-zod-to-types-generator-phase-4-v2.md | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\include\DATA_SCHEMA.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\essential_only\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\docs\designs\_15_to_22\2026-03-25-zod-to-types-generator-phase-4-v2.md | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\EXTRACCIONES_FULL\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\include\DATA_SCHEMA.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\essential_only\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\essential_only\src\env.ts | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\essential_only\src\env.ts | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\essential_only\src\relay\whatsapp\router.ts | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\retro\_downloads\PPSSPPWindowsARM64\assets\debugger\static\js\main.fe87e942.js | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\src\adapters\whatsapp\whatsapp.webhook.routes.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\src\config\env.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\src\config\env.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\src\config\env.js | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\README.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\vite.config.js | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\vite.config.js | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_release-notifier.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-changelog.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-docs.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-flathub-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-homebrew-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-pacman-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\_update-winget-repo.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-archlinux.yml | passwd\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-bundle.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-copr.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-copr.yml | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-homebrew.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-linux.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-macos.yml | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci-windows.yml | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | password\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\ci.yml | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\localize.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\.github\workflows\update-pages.yml | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-mvp\_archive\source-zips\Sunshine-master\Sunshine-master\docs\api.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-v2-ready\runeforge-v2\src\core\auth.ts | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\codigo_y_docs_runeforge\runeforge-v2-ready\runeforge-v2\src\core\config.ts | api[_-]?key\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\docs\designs\_15_to_22\2026-03-25-zod-to-types-generator-phase-4-v2.md | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\include\DATA_SCHEMA.md | token\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\src\types.d.ts | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\src\extraction\extract.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\src\prompts\events\rules.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\src\prompts\events\schema.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\src\prompts\events\examples\en.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\src\reflection\reflect.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\src\store\schemas.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\tests\factories.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\tests\extraction\extract.test.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\tests\extraction\structured.test.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\tests\pov\pov.test.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\tests\retrieval\formatting.test.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |
| HIGH | C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_CENTRO\fuentes\notas_obsidian_2\10_PROYECTOS\REPOS\openvault-master\openvault-master\tests\retrieval\retrieve.test.js | secret\s*[:=] | No se imprime valor. Revisar manualmente. |

## 7. Archivos .env detectados
| FullName | Length | LastWriteTime |
| --- | --- | --- |
| C:\RUNEFOGE_PRO\runeforge\app\.env | 510 | 27/03/2026 07:04:56 a. m. |
| C:\RUNEFOGE_PRO\runeforge\app\.env.example | 510 | 27/03/2026 07:04:56 a. m. |
| C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\runeforge-mvp\runeforge-mvp\.env.example | 344 | 20/03/2026 06:15:07 a. m. |
| C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\.env | 1065 | 02/03/2026 12:38:18 p. m. |
| C:\Users\nesth\Documents\EL_ABISMO\DRIVE ME IPHONE\TODO\CCTV\GEMINI\APP\runeforge-relay\.env.example | 464 | 02/03/2026 12:25:52 p. m. |

## 8. Plan de normalización
| current | proposed | action | risk | reason |
| --- | --- | --- | --- | --- |
| C:\RUNEFOGE_PRO\runeforge | C:\RUNEFOGE_PRO\runeforge | MANTENER | BAJO | Raíz activa declarada. No romper referencias. |
| C:\RUNEFOGE_PRO\runeforge\app | C:\RUNEFOGE_PRO\runeforge\app | MANTENER | BAJO | Backend principal según estructura cerrada. |
| C:\RUNEFOGE_PRO\runeforge\scripts | C:\RUNEFOGE_PRO\runeforge\scripts | MANTENER | BAJO | Automatización central. Nombre simple y claro. |
| C:\RUNEFOGE_PRO\runeforge\lab | C:\RUNEFOGE_PRO\runeforge\lab | MANTENER | BAJO | Pruebas controladas. Correcto para RF Security Lab. |
| C:\RUNEFORGE_PRO | C:\RUNEFOGE_PRO\runeforge\archive\legacy_RUNEFORGE_PRO | PROPONER_MIGRACION_NO_APLICADA | ALTO | Ruta inconsistente sin E: C:\RUNEFORGE_PRO vs C:\RUNEFOGE_PRO. Requiere revisar contenido antes de mover. |
| C:\Users\nesth\Documents\EL_ABISMO | C:\Users\nesth\Documents\EL_ABISMO | MANTENER_COMO_MEMORIA_EXTERNA | MEDIO | Memoria documental/IA; no debe mezclarse con backend. |

## 9. Decisión recomendada
- No renombrar $CanonicalRoot.
- No mover $AbismoRoot.
- Revisar $LegacyWrongRoot antes de migrar.
- No volver a usar Add-MpPreference -ExclusionPath sobre árboles completos.
- Preferir puertos privados: localhost o interfaz Tailscale.
- Mantener flujo: INPUT → ROUTER → SKILL → ACTION → TRACE → RESPONSE.
