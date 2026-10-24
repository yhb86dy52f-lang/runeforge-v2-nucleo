const db=new Dexie('TGL_LAB_V5');
db.version(1).stores({
  unidades:'esn',
  telemetria:'++id,esn,timestamp,sync',
  tramas_raw:'++id,esn,timestamp,sync'
});
