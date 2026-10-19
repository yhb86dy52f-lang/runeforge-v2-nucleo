class UnidadCompleta {
  final String codigo;
  final int unidadId;
  final String estado;
  final String mac;
  final String gpsMarcaModelo;
  final String tipo;
  final String tecnico;
  final DateTime fechaInstalacion;
  final int beaconId;

  UnidadCompleta({required this.codigo, required this.unidadId, required this.estado, required this.mac, required this.gpsMarcaModelo, required this.tipo, required this.tecnico, required this.fechaInstalacion, required this.beaconId});

  factory UnidadCompleta.fromJson(Map<String, dynamic> json) {
    return UnidadCompleta(
      codigo: json['codigo'],
      unidadId: json['unidad_id'],
      estado: json['estado'],
      mac: json['mac'],
      gpsMarcaModelo: json['gps_marca_modelo'],
      tipo: json['tipo'],
      tecnico: json['tecnico'],
      fechaInstalacion: DateTime.parse(json['fecha_instalacion']),
      beaconId: json['beacon_id'],
    );
  }
}
