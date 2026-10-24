
export function parseR0(input:string){
  var m = function(re:RegExp){ var v=input.match(re); return v?v[1]:null }
  return {
    family:'R0' as const,
    estado:'STATUS OK',
    color:'blue',
    appVer: m(/APP:(\d+)/i),
    appRev: m(/APP:\d+\s+([^\s]+)/i),
    rssi: (function(){var x=input.match(/COM:(-?\d+)/i); return x?parseInt(x[1]):null})(),
    apn: m(/DA\.\s*([^\s]+)/i),
    gpsFix: m(/GPS:([^\s]+)/i),
    sats: (function(){var x=input.match(/GPS:[^\s]+\s+(\d+)/i); return x?parseInt(x[1]):null})(),
    inpBin: m(/INP:([01]+)/i),
    mid: m(/MID:(\d+)/i),
    esn: m(/ESN:([^\s]+)/i),
    inb: m(/INB:([^\s]+)/i),
    raw:input
  }
}

export function detectFamily(input:string): 'CT'|'KW'|'R0'{
  var up = input.toUpperCase()
  if(up.indexOf('ACCUM_')!==-1 || up.indexOf('ESC_LEV')!==-1 || up.indexOf('S-LITROS')!==-1 || up.indexOf('LITROS V1')!==-1) return 'KW'
  if(up.indexOf('APP:')!==-1 && up.indexOf('MID:')!==-1) return 'R0'
  if(up.indexOf('APP:')!==-1 && up.indexOf('INP:')!==-1) return 'R0'
  var clean = up.replace(/[^0-9A-F]/g,'')
  if(clean.length>=40) return 'CT'
  return 'CT'
}
