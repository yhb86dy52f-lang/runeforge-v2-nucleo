# RUNEFORGE FIX02 PORT CONTEXT

Fecha: 2026-04-25T02:48:32
Modo: READ_ONLY

## Listeners objetivo

- :::22 | pid=10040 | process=sshd | allInterfaces=True | path=C:\Program Files\OpenSSH-Win64\sshd.exe
- 0.0.0.0:22 | pid=10040 | process=sshd | allInterfaces=True | path=C:\Program Files\OpenSSH-Win64\sshd.exe
- :::3100 | pid=9020 | process=node | allInterfaces=True | path=C:\Program Files\nodejs\node.exe
- :::8082 | pid=4608 | process=java | allInterfaces=True | path=C:\Program Files\Traccar\jre\bin\java.exe
- 0.0.0.0:47990 | pid=3724 | process=sunshine | allInterfaces=True | path=C:\Program Files\Sunshine\Sunshine.exe


## SSHD config summary

- Port 22
- PubkeyAuthentication yes
- PasswordAuthentication yes
- AllowUsers nesth


## Runeforge listen hints

- C:\RUNEFOGE_PRO\runeforge\app\src\server.js:6 :: app.listen(env.port, () => {
- C:\RUNEFOGE_PRO\runeforge\app\src\config\env.js:15 :: port: Number(process.env.PORT || 3100),
- C:\RUNEFOGE_PRO\runeforge\app\src\modules\chat\skills\system.js:22 :: { key: 'hostname', value: os.hostname() }


## Firewall allow rules relevantes

- Servidor de streaming de Transmitir en dispositivo (streaming por RTCP de entrada) | profile=Public | port=Any | program=%SystemRoot%\system32\mdeserver.exe | remote=PlayToDevice
- Servidor de streaming de Transmitir en dispositivo (streaming por RTCP de entrada) | profile=Private | port=Any | program=%SystemRoot%\system32\mdeserver.exe | remote=LocalSubnet
- Servidor de streaming de Transmitir en dispositivo (streaming por RTCP de entrada) | profile=Domain | port=Any | program=%SystemRoot%\system32\mdeserver.exe | remote=Any
- Asistencia remota (TCP de entrada) | profile=Domain, Private | port=Any | program=%SystemRoot%\system32\msra.exe | remote=Any
- Asistencia remota (TCP de servidor de RA de entrada) | profile=Domain | port=Any | program=%SystemRoot%\system32\raserver.exe | remote=Any
- Pantalla inalámbrica (TCP de entrada) | profile=Any | port=Any | program=%systemroot%\system32\WUDFHost.exe | remote=Any
- Uso del servicio de digitalización de Wi-Fi Direct (entrada) | profile=Public | port=Any | program=%SystemRoot%\system32\svchost.exe | remote=Any
- Uso de administrador de trabajos en cola de Wi-Fi Direct (entrada) | profile=Public | port=Any | program=%SystemRoot%\system32\spoolsv.exe | remote=Any
- Detección de redes Wi-Fi Direct (entrada) | profile=Public | port=Any | program=%SystemRoot%\system32\dashost.exe | remote=Any
- Enrutador de AllJoyn (UDP de entrada) | profile=Domain, Private | port=Any | program=%SystemRoot%\system32\svchost.exe | remote=Any
- Detección de redes para Teredo (UPnP de entrada) | profile=Public | port=Any | program=System | remote=Any
- Detección de redes para Teredo (SSDP de entrada) | profile=Public | port=Any | program=%SystemRoot%\system32\svchost.exe | remote=Any
- Uso compartido de proximidad sobre TCP (uso compartido de TCP de entrada) | profile=Any | port=Any | program=%SystemRoot%\system32\proximityuxhost.exe | remote=Any
- Redes principales: IPv6 (IPv6 de entrada) | profile=Any | port=Any | program=System | remote=Any
- Redes principales: Protocolo de administración de grupo de Internet (IGMP de entrada) | profile=Any | port=Any | program=System | remote=Any
- Plataforma de dispositivos conectados: transporte de Wi-Fi Direct (TCP-In) | profile=Public | port=Any | program=%SystemRoot%\system32\svchost.exe | remote=Any
- Plataforma de dispositivos conectados (TCP-In) | profile=Domain, Private | port=Any | program=%SystemRoot%\system32\svchost.exe | remote=Any
- Plataforma de dispositivos conectados (UDP-In) | profile=Domain, Private | port=Any | program=%SystemRoot%\system32\svchost.exe | remote=Any
- Solo el controlador de WFD (UDP de entrada) | profile=Any | port=Any | program=System | remote=Any
- Solo el controlador de WFD (TCP de entrada) | profile=Any | port=Any | program=System | remote=Any
- Brave Browser | profile=Private | port=Any | program=C:\program files\bravesoftware\brave-browser\application\brave.exe | remote=Any
- Brave Browser | profile=Private | port=Any | program=C:\program files\bravesoftware\brave-browser\application\brave.exe | remote=Any
- SmartPSSLite | profile=Private | port=Any | program=C:\program files\smartpsslite\smartpsslite.exe | remote=Any
- SmartPSSLite | profile=Private | port=Any | program=C:\program files\smartpsslite\smartpsslite.exe | remote=Any
- opera.exe | profile=Private | port=Any | program=C:\users\nesth\appdata\local\programs\opera gx\opera.exe | remote=Any
- opera.exe | profile=Private | port=Any | program=C:\users\nesth\appdata\local\programs\opera gx\opera.exe | remote=Any
- Solitaire & Casual Games | profile=Domain, Private | port=Any | program=Any | remote=Any
- AirServer® Universal | profile=Private | port=Any | program=C:\program files\app dynamic\airserver\airserver.exe | remote=Any
- AirServer® Universal | profile=Private | port=Any | program=C:\program files\app dynamic\airserver\airserver.exe | remote=Any
- Sunshine TCP | profile=Any | port=47984-48010 | program=Any | remote=Any
- Sunshine UDP | profile=Any | port=47984-48010 | program=Any | remote=Any
- Steam | profile=Domain, Private, Public | port=Any | program=C:\Program Files (x86)\Steam\steam.exe | remote=Any
- Steam | profile=Domain, Private, Public | port=Any | program=C:\Program Files (x86)\Steam\steam.exe | remote=Any
- Steam Web Helper | profile=Domain, Private, Public | port=Any | program=C:\Program Files (x86)\Steam\bin\cef\cef.win64\steamwebhelper.exe | remote=Any
- Steam Web Helper | profile=Domain, Private, Public | port=Any | program=C:\Program Files (x86)\Steam\bin\cef\cef.win64\steamwebhelper.exe | remote=Any
- EA app (EABackgroundService) | profile=Any | port=Any | program=C:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EABackgroundService.exe | remote=Any
- EA app (EAConnect_microsoft) | profile=Any | port=Any | program=C:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EAConnect_microsoft.exe | remote=Any
- EA app (EADesktop) | profile=Any | port=Any | program=C:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EADesktop.exe | remote=Any
- EA app (EAGEP) | profile=Any | port=Any | program=C:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EAGEP.exe | remote=Any
- EA app (EALocalHostSvc) | profile=Any | port=Any | program=C:\Program Files\Electronic Arts\EA Desktop\EA Desktop\EALocalHostSvc.exe | remote=Any
- Battlefield™ 1 | profile=Private | port=Any | program=G:\steamlibrary\steamapps\common\battlefield 1\bf1.exe | remote=Any
- Battlefield™ 1 | profile=Private | port=Any | program=G:\steamlibrary\steamapps\common\battlefield 1\bf1.exe | remote=Any
- termius.exe | profile=Private | port=Any | program=C:\users\nesth\appdata\local\programs\termius\termius.exe | remote=Any
- termius.exe | profile=Private | port=Any | program=C:\users\nesth\appdata\local\programs\termius\termius.exe | remote=Any
- Google Chrome | profile=Private | port=Any | program=C:\program files\google\chrome\application\chrome.exe | remote=Any
- Google Chrome | profile=Private | port=Any | program=C:\program files\google\chrome\application\chrome.exe | remote=Any
- anythingllm.exe | profile=Private | port=Any | program=C:\users\nesth\appdata\local\programs\anythingllm\anythingllm.exe | remote=Any
- anythingllm.exe | profile=Private | port=Any | program=C:\users\nesth\appdata\local\programs\anythingllm\anythingllm.exe | remote=Any
- Allow SSH | profile=Any | port=22 | program=Any | remote=Any
- Runeforge SSH 22 | profile=Private | port=22 | program=Any | remote=Any
- OpenSSH Server | profile=Any | port=22 | program=Any | remote=Any
- OpenSSH Server | profile=Any | port=22 | program=Any | remote=Any
- OpenSSH Server | profile=Any | port=22 | program=Any | remote=Any
- Node.js JavaScript Runtime | profile=Private | port=Any | program=C:\program files\nodejs\node.exe | remote=Any
- Node.js JavaScript Runtime | profile=Private | port=Any | program=C:\program files\nodejs\node.exe | remote=Any
- EpicGamesLauncher | profile=Private | port=Any | program=C:\program files\epic games\launcher\portal\binaries\win64\epicgameslauncher.exe | remote=Any
- EpicGamesLauncher | profile=Private | port=Any | program=C:\program files\epic games\launcher\portal\binaries\win64\epicgameslauncher.exe | remote=Any
- DTS Sound Unbound | profile=Domain, Private | port=Any | program=Any | remote=Any
- Windows Search | profile=Domain, Private | port=Any | program=Any | remote=Any
- Tailscale-Process | profile=Any | port=Any | program=C:\Program Files\Tailscale\tailscaled.exe | remote=Any
- Tailscale-In | profile=Domain, Private | port=Any | program=Any | remote=Any
- Tailscale-In | profile=Domain, Private | port=Any | program=Any | remote=Any
- Instalador de aplicación | profile=Domain, Private | port=Any | program=Any | remote=Any
- ChatGPT | profile=Any | port=Any | program=C:\Program Files\WindowsApps\OpenAI.ChatGPT-Desktop_1.2026.43.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe | remote=Any
- ChatGPT | profile=Any | port=Any | program=C:\Program Files\WindowsApps\OpenAI.ChatGPT-Desktop_1.2026.43.0_x64__2p2nqsd0c76g0\app\ChatGPT.exe | remote=Any
- ChatGPT | profile=Domain, Private, Public | port=Any | program=Any | remote=Any
- Microsoft Store | profile=Domain, Private, Public | port=Any | program=Any | remote=Any
- Microsoft 365 Copilot | profile=Domain, Private, Public | port=Any | program=Any | remote=Any


## Nota

No se modificó firewall.
No se cerró ningún puerto.
No se leyó .env.
No se leyeron configs sensibles de Traccar/Sunshine.
