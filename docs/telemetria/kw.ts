
export function parseKW(input:string){
  var get = function(re:RegExp){ var m=input.match(re); return m?parseInt(m[1]):null }
  var accum0 = get(/accum_0\s*[:=]\s*(\d+)/i)
  var accum1 = get(/accum_1\s*[:=]\s*(\d+)/i)
  var accum2 = get(/accum_2\s*[:=]\s*(\d+)/i)
  var accum3 = get(/accum_3\s*[:=]\s*(\d+)/i)
  var accum4 = get(/accum_4\s*[:=]\s*(\d+)/i)
  var accum5 = get(/accum_5\s*[:=]\s*(\d+)/i)
  var accum6 = get(/accum_6\s*[:=]\s*(\d+)/i)
  var rssi = get(/rssi\s*=\s*(-?\d+)/i)
  if(rssi===null) rssi = get(/COM:(-?\d+)/i)
  var midM = input.match(/MID:(\d+)/)
  var inpM = input.match(/INP:([01]+)/)
  var inpBin = inpM ? inpM[1] : null
  var inVal = get(/in\s*[:=]\s*(\d+)/i)
  if(!inVal && inpBin){ inVal = parseInt(inpBin.slice(-5),2) }
  var lev1 = get(/S-Litros V1\s*[:=]\s*(\d+)/i)
  if(lev1===null) lev1 = get(/Nivel.*Tanque 1\s*[:=]\s*(\d+)/i) || 0
  var lev2 = get(/S-Litros V2\s*[:=]\s*(\d+)/i)
  if(lev2===null) lev2 = get(/Nivel.*Tanque 2\s*[:=]\s*(\d+)/i) || 0
  var litrosTotales = get(/S-Litros totales\s*[:=]\s*0*(\d+)/i)
  if(litrosTotales===null) litrosTotales = (lev1+lev2) || null
  var voltU = accum0 ? accum0/1000 : 12.0
  var voltG = accum1 ? accum1/1000 : 4.0
  var odo = accum5 ? accum5/1000 : null
  return { family:'KW', estado:'COMBUSTIBLE OK', color:'green', voltU:voltU, voltG:voltG, odo:odo, lev1:lev1, lev2:lev2, litrosTotales:litrosTotales, rssi:rssi, mid:midM?midM[1]:null, raw:input }
}
