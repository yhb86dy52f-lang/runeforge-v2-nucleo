#!/data/data/com.termux/files/usr/bin/bash
set -e
cd ~/public/DECODE
echo "🌴 OASIS FINAL - RECREA + PARCHEA SIN INTERNET"
# Recrea assets
cat > index.html <<'HTML_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>SEPCOLGPS NEXUS v20 MOBILE</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&family=Space+Grotesk:wght@700;900&display=swap');
:root{--bg:#030508;--panel:rgba(10,16,30,0.82);--border:rgba(255,255,255,0.08);--green:#3dd598;--blue:#2d6cdf;--red:#ff4757;--text:#e2e8f0;--muted:#94a3b8}
*{box-sizing:border-box}html,body{margin:0;background:var(--bg);color:var(--text);font-family:'JetBrains Mono',monospace}
.app{min-height:100vh;padding:0 12px 20px;position:relative}
.bg{position:fixed;inset:0;pointer-events:none;background:radial-gradient(800px 400px at 20% -10%, rgba(61,213,152,0.22), transparent), radial-gradient(600px 300px at 80% 0%, rgba(45,108,223,0.28), transparent)}
.hdr{position:sticky;top:0;z-index:10;backdrop-filter:blur(16px);background:rgba(0,0,0,0.4);border-bottom:1px solid var(--border);height:56px;display:flex;align-items:center;justify-content:space-between;padding:0 12px;margin:0 -12px}
.logo{width:32px;height:32px;border-radius:10px;background:linear-gradient(135deg,var(--green),var(--blue));display:flex;align-items:center;justify-content:center;font-weight:900;color:#000}
h1{font-family:'Space Grotesk';font-size:13px;margin:0}small{font-size:9px;color:var(--muted);letter-spacing:0.2em}
.glass{background:var(--panel);backdrop-filter:blur(20px);border:1px solid var(--border);border-radius:20px;padding:14px;margin-top:12px;box-shadow:0 10px 40px rgba(0,0,0,0.6)}
.ta{width:100%;height:140px;background:rgba(0,0,0,0.5);border:1px solid rgba(255,255,255,0.1);border-radius:14px;padding:10px;color:var(--green);font-family:'JetBrains Mono';font-size:11px;outline:none}
.btn{height:42px;border-radius:12px;border:none;font-weight:900;cursor:pointer;letter-spacing:0.1em}
.primary{flex:1;background:linear-gradient(90deg,var(--green),var(--blue));color:#000}
.ghost{width:42px;background:rgba(255,255,255,0.08);border:1px solid var(--border);color:#fff}
.row{display:flex;gap:8px;margin-top:8px}
.pres{display:flex;gap:6px;margin-top:8px;flex-wrap:wrap}
.pres button{padding:6px 10px;border-radius:10px;background:rgba(255,255,255,0.06);border:1px solid var(--border);color:var(--muted);font-size:10px}
.badge{padding:6px 10px;border-radius:999px;font-weight:800;font-size:10px;border:1px solid}
.green{background:rgba(61,213,152,0.15);color:#a7f3d0;border-color:rgba(61,213,152,0.3)}
.red{background:rgba(255,71,87,0.15);color:#fecdd3;border-color:rgba(255,71,87,0.3)}
.yellow{background:rgba(234,179,8,0.15);color:#fde68a;border-color:rgba(234,179,8,0.3)}
.blue{background:rgba(45,108,223,0.15);color:#bfdbfe;border-color:rgba(45,108,223,0.3)}
.muted{background:rgba(255,255,255,0.06);color:var(--muted);border-color:var(--border)}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.kv{font-size:11px;line-height:1.5;display:flex;flex-direction:column;gap:4px}
.kv b{color:var(--green)}
.gauge{display:flex;flex-direction:column;align-items:center;gap:6px;padding:10px;background:var(--panel);border:1px solid var(--border);border-radius:16px}
</style>
</head>
<body>
<div class="bg"></div>
<div class="app">
  <div class="hdr"><div style="display:flex;gap:10px;align-items:center"><div class="logo">S</div><div><h1>SEPCOLGPS NEXUS v20 MOBILE</h1><small>DESCENTRALIZADO • SOLO ESTE DISPOSITIVO</small></div></div><span id="fam" class="badge muted">--</span></div>

  <div class="glass">
    <small style="color:rgba(255,255,255,0.4);letter-spacing:0.2em">TRAMA GPS • AUTO-DETECT CT/KW/R0</small>
    <textarea id="input" class="ta">!E4675022428:444 8.6l COM:-82 DA. INTERNET.ITELCEL.COM GPS:3D-DIFF 17 INP:1000000000011110 12.0V MID:4675022428 ESN INB:94.130.84.182:20785 LMD APP2:REV10979-REL
rssi=-65, hdop=0.7, accum_0=12585, accum_1=4004, accum_2=2099230, accum_3=0, accum_4=0, accum_5=4348636, accum_6=0, report_type=9, in=30</textarea>
    <div class="row"><button class="btn primary" onclick="decode()">DECODIFICAR →</button><button class="btn ghost" onclick="navigator.clipboard.writeText(document.getElementById('input').value)">⎙</button><button class="btn ghost" onclick="document.getElementById('input').value='';document.getElementById('out').innerHTML=''">✕</button></div>
    <div class="pres"><button onclick="loadCT()">Ejemplo CT 24°C / 12.16V</button><button onclick="loadKW()">Ejemplo KW 164/184L 4348km</button></div>
  </div>

  <div id="out"></div>
</div>

<script>
// ===== PARSERS VALIDADO CT227 + KW758 - sin includes, solo indexOf =====
function detectFamily(s){
  var up=s.toUpperCase();
  if(up.indexOf('ACCUM_')!==-1 || up.indexOf('ESC_LEV')!==-1 || up.indexOf('S-LITROS')!==-1) return 'KW';
  if(up.indexOf('APP:')!==-1 && up.indexOf('MID:')!==-1) return 'R0';
  if(up.indexOf('APP:')!==-1 && up.indexOf('INP:')!==-1) return 'R0';
  var clean=up.replace(/[^0-9A-F]/g,''); if(clean.length>=40) return 'CT'; return 'CT';
}
function parseCT(input){
  var clean=input.toUpperCase().replace(/[^0-9A-F]/g,'');
  var bytes=[]; for(var i=0;i<clean.length;i+=2) bytes.push(parseInt(clean.substr(i,2),16));
  var u16=[]; for(var j=0;j<bytes.length-1;j+=2) u16.push((bytes[j]<<8)|bytes[j+1]);
  var accum0=null,accum1=null; for(var k=u16.length-1;k>=0;k--){ if(u16[k]>=10000&&u16[k]<=16000&&!accum0) accum0=u16[k]; if(u16[k]>=3500&&u16[k]<=5000&&!accum1) accum1=u16[k]; }
  var small=u16.filter(function(v){return v>0&&v<1000;});
  var accum2=small.length>=2?small[small.length-2]:small[0]||null;
  var accum3=small.length>=2?small[small.length-1]:null;
  var m; m=input.match(/accum_0\s*[:=]\s*(\d+)/i); if(m) accum0=parseInt(m[1]);
  m=input.match(/accum_1\s*[:=]\s*(\d+)/i); if(m) accum1=parseInt(m[1]);
  m=input.match(/accum_2\s*[:=]\s*(\d+)/i); if(m) accum2=parseInt(m[1]);
  m=input.match(/accum_3\s*[:=]\s*(\d+)/i); if(m) accum3=parseInt(m[1]);
  var c3E70=u16.filter(function(v){return v===0x3E70;}).length;
  var cFFFF=u16.filter(function(v){return v===0xFFFF;}).length;
  var voltU=accum0?accum0/1000:null, voltG=accum1?accum1/1000:null;
  var tempC1=accum2?accum2/16:null, tempC2=accum3?accum3/16:null;
  var estado='BUENO PERFECTO', color='green', msg='Sondas OK';
  if(c3E70>=2){estado='FALLA DOBLE TERMO';color='red';msg='2x 15984 ambas abiertas';}
  else if(c3E70===1){estado='FALLA SIMPLE';color='yellow';msg='1x 15984';}
  else if(cFFFF>=2){estado='OK DESHABILITADO';color='blue';msg='FFFF';}
  var rssiM=input.match(/rssi\s*=\s*(-?\d+)/i)||input.match(/COM:(-?\d+)/);
  var midM=input.match(/MID:(\d+)/);
  return {family:'CT',estado:estado,color:color,msg:msg,voltU:voltU,voltG:voltG,tempC1:tempC1,tempC2:tempC2,accum0:accum0,accum1:accum1,accum2:accum2,accum3:accum3,c3E70:c3E70,cFFFF:cFFFF,rssi:rssiM?parseInt(rssiM[1]):null,mid:midM?midM[1]:null,raw:input};
}
function parseKW(input){
  var get=function(re){var m=input.match(re);return m?parseInt(m[1]):null;};
  var accum0=get(/accum_0\s*[:=]\s*(\d+)/i), accum1=get(/accum_1\s*[:=]\s*(\d+)/i), accum2=get(/accum_2\s*[:=]\s*(\d+)/i), accum3=get(/accum_3\s*[:=]\s*(\d+)/i), accum5=get(/accum_5\s*[:=]\s*(\d+)/i);
  var rssi=get(/rssi\s*=\s*(-?\d+)/i)||get(/COM:(-?\d+)/i);
  var midM=input.match(/MID:(\d+)/); var lev1=get(/S-Litros V1\s*[:=]\s*(\d+)/i)||0; var lev2=get(/S-Litros V2\s*[:=]\s*(\d+)/i)||0;
  var litros=get(/S-Litros totales\s*[:=]\s*0*(\d+)/i); if(!litros) litros=lev1+lev2||null;
  var voltU=accum0?accum0/1000:12, voltG=accum1?accum1/1000:4, odo=accum5?accum5/1000:null;
  return {family:'KW',estado:'COMBUSTIBLE OK',color:'green',voltU:voltU,voltG:voltG,odo:odo,lev1:lev1,lev2:lev2,litros:litros,rssi:rssi,mid:midM?midM[1]:null,raw:input,accum2:accum2,accum3:accum3};
}
function parseR0(input){
  var m=function(re){var v=input.match(re);return v?v[1]:null;};
  return {family:'R0',estado:'STATUS OK',color:'blue',appVer:m(/APP:(\d+)/i),rssi:(function(){var x=input.match(/COM:(-?\d+)/);return x?parseInt(x[1]):null;})(),mid:m(/MID:(\d+)/),raw:input};
}

function render(data){
  var html='<div class="glass"><div style="display:flex;gap:8px;flex-wrap:wrap"><span class="badge '+data.color+'">'+data.estado+'</span>';
  if(data.rssi!=null) html+='<span class="badge muted">RSSI '+data.rssi+' dBm</span>';
  if(data.mid) html+='<span class="badge muted">MID '+data.mid+'</span>';
  html+='</div>';
  if(data.family==='CT'){
    html+='<div class="grid2" style="margin-top:12px"><div class="gauge"><small>Volt Unidad</small><b style="font-size:20px;color:var(--green)">'+(data.voltU!=null?data.voltU.toFixed(2)+'V':'--')+'</b><small>accum0 '+data.accum0+'</small></div><div class="gauge"><small>Volt GPS</small><b style="font-size:20px;color:var(--blue)">'+(data.voltG!=null?data.voltG.toFixed(2)+'V':'--')+'</b><small>accum1 '+data.accum1+'</small></div><div class="gauge"><small>Temp1</small><b style="font-size:20px">'+(data.tempC1!=null?data.tempC1.toFixed(1)+'°C':'--')+'</b><small>accum2 '+data.accum2+' /16</small></div><div class="gauge"><small>Temp2</small><b style="font-size:20px">'+(data.tempC2!=null?data.tempC2.toFixed(1)+'°C':'--')+'</b><small>accum3 '+data.accum3+' /16</small></div></div>';
    html+='<div class="kv" style="margin-top:10px"><div><b>c_3E70</b> '+data.c3E70+' (15984 = falla) • <b>c_FFFF</b> '+data.cFFFF+'</div><div>'+data.msg+'</div></div>';
  }
  if(data.family==='KW'){
    html+='<div class="grid2" style="margin-top:12px"><div class="gauge"><small>Volt U</small><b style="font-size:20px">'+data.voltU+'V</b></div><div class="gauge"><small>Odo</small><b style="font-size:20px">'+(data.odo!=null?data.odo+'km':'--')+'</b></div><div class="gauge"><small>Tanque1</small><b style="font-size:20px">'+data.lev1+'L</b></div><div class="gauge"><small>Tanque2</small><b style="font-size:20px">'+data.lev2+'L</b></div></div><div class="kv" style="margin-top:10px"><div><b>Total</b> '+data.litros+'L</div><div><b>accum2</b> '+data.accum2+' <b>accum3</b> '+data.accum3+'</div></div>';
  }
  html+='</div>';
  document.getElementById('out').innerHTML=html;
}
function decode(){
  var input=document.getElementById('input').value;
  var fam=detectFamily(input);
  document.getElementById('fam').textContent=fam;
  var data;
  if(fam==='KW') data=parseKW(input);
  else if(fam==='R0') data=parseR0(input);
  else data=parseCT(input);
  render(data);
}
function loadCT(){document.getElementById('input').value='!E7000276162:445 8.7b COM:-82 DA. internet.itelcel.com GPS:3D-DIFF 20 INP:0000000000000110 12.4V MID:7000276162 ESN INB:94.130.84.182:20924 LMD APP2:REV12335-REL\\naccum_0=12160, accum_1=4077, accum_2=384, accum_3=399, c_3E70=0, c_FFFF=0';decode();}
function loadKW(){document.getElementById('input').value='!E4675022428:444 8.6l COM:-82 DA. INTERNET.ITELCEL.COM GPS:3D-DIFF 17 INP:1000000000011110 12.0V MID:4675022428 ESN INB:94.130.84.182:20785 LMD APP2:REV10979-REL\\nrssi=-65, accum_0=12585, accum_1=4004, accum_2=2099230, accum_3=0, accum_5=4348636, S-Litros V1=164, S-Litros V2=184, S-Litros totales=348';decode();}
window.onload=decode;
</script>
</body>
</html>

HTML_EOF
echo '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' | base64 -d > icon.png
echo "✅ index.html $(wc -c < index.html) bytes"
echo "✅ icon.png $(wc -c < icon.png) bytes"

# Verifica toolchain
for b in aapt2 apksigner d8 java javac keytool zip unzip; do [ -f $PREFIX/bin/$b ] && echo "✅ $b" || { echo "❌ $b"; exit 1; }; done

# Keystore
if [ -f termux-apktool/apk_build/assets/my-release-key.keystore ]; then
  cp termux-apktool/apk_build/assets/my-release-key.keystore ./my-release-key.keystore
fi
if [ ! -f my-release-key.keystore ]; then
  keytool -genkeypair -keystore my-release-key.keystore -alias app -keyalg RSA -keysize 2048 -validity 10000 -storepass 123456 -keypass 123456 -dname "CN=OASIS" > /dev/null 2>&1
fi

BASE_APK=/sdcard/Download/SEPCOLGPS.apk
if [ ! -f $BASE_APK ]; then
  echo "❌ No hay $BASE_APK"
  ls /sdcard/Download/*.apk
  exit 1
fi

rm -rf /tmp/oasis_patch
mkdir -p /tmp/oasis_patch/assets
cp index.html icon.png /tmp/oasis_patch/assets/
cp app.css ct.js kw.js r0.js /tmp/oasis_patch/assets/ 2>/dev/null || true

cp $BASE_APK /tmp/patched_unsigned.apk
cd /tmp/oasis_patch
zip -r /tmp/patched_unsigned.apk assets/ -q
echo "🔄 Assets parcheados"

cd ~/public/DECODE
rm -f /tmp/final.apk
apksigner sign --ks my-release-key.keystore --ks-pass pass:123456 --min-sdk-version 21 --out /tmp/final.apk /tmp/patched_unsigned.apk
cp /tmp/final.apk /sdcard/Download/SEPCOLGPS_OFFLINE_FINAL.apk
ls -lh /sdcard/Download/SEPCOLGPS_OFFLINE_FINAL.apk
echo "📂 Listo: /sdcard/Download/SEPCOLGPS_OFFLINE_FINAL.apk"
termux-open --content-type application/vnd.android.package-archive /sdcard/Download/SEPCOLGPS_OFFLINE_FINAL.apk
