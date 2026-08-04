# RF PC TOOLCHAIN AUDIT V1

Fecha: 2026-05-23 12:08:05

## Resumen

Required missing: 0
Optional missing: 2
Paths missing: 0
Backend: NO_TOCADO
n8n runtime: NO_TOCADO

## Herramientas

- ✅ PowerShell 7 | required=True | exists=True | version=[31;1mParserError: [0m [31;1m[36;1mLine |[0m [31;1m[36;1m[36;1m   1 | [0m System.Management.Automation.PSVersionHashTable.PSVersion.ToString([36;1m)[0m [31;1m[36;1m[36;1m[0m[36;1m[0m[36;1m     | [31;1m                                                                    ~[0m [31;1m[36;1m[36;1m[0m[36;1m[0m[36;1m[31;1m[31;1m[36;1m     | [31;1mAn expression was expected[0m | path=C:\Program Files\PowerShell\7\pwsh.exe
- ✅ Node.js global | required=True | exists=True | version=v20.11.1 | path=C:\Program Files\nodejs\node.exe
- ✅ npm global | required=True | exists=True | version=10.2.4 | path=C:\Program Files\nodejs\npm.cmd
- ✅ PM2 | required=True | exists=True | version=6.0.14 | path=C:\Users\nesth\AppData\Roaming\npm\pm2.ps1
- ✅ Git | required=True | exists=True | version=git version 2.44.0.windows.1 | path=C:\Program Files\Git\cmd\git.exe
- ✅ Python | required=False | exists=True | version=no se encontr� Python; ejecutar sin argumentos para instalar desde el Microsoft Store o deshabilitar este acceso directo desde Configuraci�n > Aplicaciones > Configuraci�n avanzada de aplicaciones > Alias de ejecuci�n de aplicaciones. | path=C:\Users\nesth\AppData\Local\Microsoft\WindowsApps\python.exe
- ⚠️ Python launcher | required=False | exists=False | version=NO_DETECTADO | path=NO_DETECTADO
- ✅ FFmpeg | required=False | exists=True | version=ffmpeg version 8.1-full_build-www.gyan.dev Copyright (c) 2000-2026 the FFmpeg developers built with gcc 15.2.0 (Rev11, Built by MSYS2 project) configuration: --enable-gpl --enable-version3 --enable-static --disable-w32threads --disable-autodetect --enable-cairo --enable-fontconfig --enable-iconv --enable-gnutls --enable-lcms2 --enable-libxml2 --enable-gmp --enable-bzlib --enable-lzma --enable-libsnappy --enable-zlib --enable-librist --enable-libsrt --enable-libssh --enable-libzmq --enable-avisynth --enable-libbluray --enable-libcaca --enable-libdvdnav --enable-libdvdread --enable-sdl2 --enable-libaribb24 --enable-libaribcaption --enable-libdav1d --enable-libdavs2 --enable-libopenjpeg --enable-libquirc --enable-libuavs3d --enable-libxevd --enable-libzvbi --enable-liboapv --enable-libqrencode --enable-librav1e --enable-libsvtav1 --enable-libvvenc --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxavs2 --enable-libxeve --enable-libxvid --enable-libaom --enable-libjxl --enable-libsvtjpegxs --enable-libvpx --enable-mediafoundation --enable-libass --enable-frei0r --enable-libfreetype --enable-libfribidi --enable-libharfbuzz --enable-liblensfun --enable-libvidstab --enable-libvmaf --enable-libzimg --enable-amf --enable-cuda-llvm --enable-cuvid --enable-dxva2 --enable-d3d11va --enable-d3d12va --enable-ffnvcodec --enable-libvpl --enable-nvdec --enable-nvenc --enable-vaapi --enable-libshaderc --enable-vulkan --enable-libplacebo --enable-opencl --enable-libcdio --enable-openal --enable-libgme --enable-libmodplug --enable-libopenmpt --enable-libopencore-amrwb --enable-libmp3lame --enable-libshine --enable-libtheora --enable-libtwolame --enable-libvo-amrwbenc --enable-libcodec2 --enable-libilbc --enable-libgsm --enable-liblc3 --enable-libopencore-amrnb --enable-libopus --enable-libspeex --enable-libvorbis --enable-ladspa --enable-libbs2b --enable-libflite --enable-libmysofa --enable-librubberband --enable-libsoxr --enable-chromaprint --enable-whisper libavutil      60. 26.100 / 60. 26.100 libavcodec     62. 28.100 / 62. 28.100 | path=C:\Users\nesth\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffmpeg.exe
- ⚠️ SQLite CLI | required=False | exists=False | version=NO_DETECTADO | path=NO_DETECTADO
- ✅ OpenSSH client | required=True | exists=True | version=OpenSSH_for_Windows_9.8p2 Win32-OpenSSH-GitHub, LibreSSL 4.0.0 | path=C:\Program Files\OpenSSH-Win64\ssh.exe
- ✅ Tailscale | required=True | exists=True | version=1.96.3   tailscale commit: 3ffddb1344a2ca023f3f6998b915351eae3d5d67   long version: 1.96.3-t3ffddb134-g460d8764a   other commit: 460d8764aa91f4859f44e9f7f4dcb48edc1fb451   go version: go1.26.1 | path=C:\Program Files\Tailscale\tailscale.exe
- ✅ VS Code CLI | required=False | exists=True | version=1.120.0 0958016b2af9f09bb4257e0df4a95e2f90590f9f x64 | path=C:\Users\nesth\AppData\Local\Programs\Microsoft VS Code\bin\code.cmd

## Rutas

- ✅ Root: C:\RUNEFOGE_PRO\runeforge
- ✅ App: C:\RUNEFOGE_PRO\runeforge\app
- ✅ Data: C:\RUNEFOGE_PRO\runeforge\data
- ✅ Traces: C:\RUNEFOGE_PRO\runeforge\data\traces
- ✅ Reports: C:\RUNEFOGE_PRO\runeforge\data\reports
- ✅ LabN8n: C:\RUNEFOGE_PRO\runeforge\lab\n8n
- ✅ N8nCanary: C:\RUNEFOGE_PRO\runeforge\lab\n8n\runtime_canary_2_20_12
- ✅ N8nUserFolder: C:\RUNEFOGE_PRO\runeforge\data\n8n_canary_2_20_12
- ✅ N8nCmd: C:\RUNEFOGE_PRO\runeforge\lab\n8n\runtime_canary_2_20_12\node_modules\.bin\n8n.cmd
- ✅ NodePortable: C:\RUNEFOGE_PRO\runeforge\tools\node-n8n\node-v22.22.3-win-x64\node.exe
- ✅ NpmPortable: C:\RUNEFOGE_PRO\runeforge\tools\node-n8n\node-v22.22.3-win-x64\npm.cmd
- ✅ ObsidianVault: C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_OBSIDIAN

## Puertos

- Port 22 | listening=True | state=Listen | pid=4280
- Port 3100 | listening=True | state=Listen | pid=16684
- Port 5680 | listening=True | state=Established | pid=18864
- Port 5510 | listening=False | state=NO_LISTENER | pid=NO_PID
- Port 5511 | listening=False | state=NO_LISTENER | pid=NO_PID
- Port 8082 | listening=True | state=Listen | pid=4328

## Servicios

- ✅ sshd | exists=True | status=Running
- ✅ Tailscale | exists=True | status=Running
- ✅ Traccar | exists=True | status=Running

## n8n Canary

Version: 2.20.12

## Missing required

- NONE

## Missing optional

- Python launcher / py
- SQLite CLI / sqlite3

## Siguiente

Pegar SUMMARY en ChatGPT para decidir si falta instalación, corrección de PATH o solo documentación.
