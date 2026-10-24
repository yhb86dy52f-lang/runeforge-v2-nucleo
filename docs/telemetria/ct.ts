
export interface CTResult{
  family:'CT'; estado:string; color:string; msg:string;
  voltU:number|null; voltG:number|null; tempC1:number|null; tempC2:number|null; tempF1:number|null; tempF2:number|null;
  accum0:number|null; accum1:number|null; accum2:number|null; accum3:number|null;
  c3E70:number; cFFFF:number; inVal:number|null; io:string|null; rssi:number|null; mid:string|null;
  raw:string
}
export function parseCT(input:string): CTResult{
  var clean = input.toUpperCase().replace(/[^0-9A-F]/g,'')
  var bytes:number[]=[]
  for(var i=0;i<clean.length;i+=2) bytes.push(parseInt(clean.slice(i,i+2),16))
  var u16:number[]=[]
  for(var j=0;j<bytes.length-1;j+=2) u16.push((bytes[j]<<8)|bytes[j+1])
  var accum0: number|null = null
  for(var k=u16.length-1;k>=0;k--){ if(u16[k]>=10000 && u16[k]<=16000){ accum0=u16[k]; break; } }
  var accum1: number|null = null
  for(var k2=u16.length-1;k2>=0;k2--){ if(u16[k2]>=3500 && u16[k2]<=5000){ accum1=u16[k2]; break; } }
  var small = u16.filter(function(v){ return v>0 && v<1000 })
  var accum2 = small.length>=2 ? small[small.length-2] : (small[0]||null)
  var accum3 = small.length>=2 ? small[small.length-1] : null
  var m0 = input.match(/accum_0\s*[:=]\s*(\d+)/i); if(m0) accum0=parseInt(m0[1])
  var m1 = input.match(/accum_1\s*[:=]\s*(\d+)/i); if(m1) accum1=parseInt(m1[1])
  var m2 = input.match(/accum_2\s*[:=]\s*(\d+)/i); if(m2) accum2=parseInt(m2[1])
  var m3 = input.match(/accum_3\s*[:=]\s*(\d+)/i); if(m3) accum3=parseInt(m3[1])
  var c3E70 = u16.filter(function(v){ return v===0x3E70 }).length
  var cFFFF = u16.filter(function(v){ return v===0xFFFF }).length
  var voltU = accum0 ? accum0/1000 : null
  var voltG = accum1 ? accum1/1000 : null
  var tempC1 = accum2 ? accum2/16 : null
  var tempC2 = accum3 ? accum3/16 : null
  var tempF1 = tempC1 ? tempC1*1.8+32 : null
  var tempF2 = tempC2 ? tempC2*1.8+32 : null
  var estado='BUENO PERFECTO', color='green', msg='Sondas Dallas OK'
  if(c3E70>=2){ estado='FALLA DOBLE TERMO'; color='red'; msg='2x 15984 = ambas sondas abiertas' }
  else if(c3E70===1){ estado='FALLA SIMPLE RESIDUAL'; color='yellow'; msg='1x 15984' }
  else if(cFFFF>=2){ estado='OK DESHABILITADO'; color='blue'; msg='FFFF deshabilitado' }
  var inM = input.match(/in\s*[:=]\s*(\d+)/i) || input.match(/INP:([01]+)/)
  var rssiM = input.match(/rssi\s*=\s*(-?\d+)/i) || input.match(/COM:(-?\d+)/)
  var midM = input.match(/MID:(\d+)/)
  var inVal = null
  if(inM){
    var raw = inM[1].replace(/[^01\d]/g,'').slice(-5)
    var baseNum = (inM[1].indexOf('0')!==-1 && inM[1].length>10) ? 2 : 10
    inVal = parseInt(raw, baseNum)
  }
  return { family:'CT', estado:estado, color:color, msg:msg, voltU:voltU, voltG:voltG, tempC1:tempC1, tempC2:tempC2, tempF1:tempF1, tempF2:tempF2, accum0:accum0, accum1:accum1, accum2:accum2, accum3:accum3, c3E70:c3E70, cFFFF:cFFFF, inVal:inVal, io:null, rssi: rssiM ? parseInt(rssiM[1]) : null, mid: midM ? midM[1] : null, raw:input }
}
