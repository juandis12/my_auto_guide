// =============================================================================
// fuel_log_model.dart — MODELO DE REGISTRO DE TANQUEO Y COMBUSTIBLE
// =============================================================================

class FuelLogModel {
  final String id;
  final String vehiculoId;
  final DateTime fecha;
  final double kmsActuales;
  final double montoCop;
  final double galones;
  final double precioPorGalon;
  final bool esTanqueLleno;
  final String? notas;

  FuelLogModel({
    required this.id,
    required this.vehiculoId,
    required this.fecha,
    required this.kmsActuales,
    required this.montoCop,
    required this.galones,
    required this.precioPorGalon,
    this.esTanqueLleno = true,
    this.notas,
  });

  factory FuelLogModel.fromJson(Map<String, dynamic> json) {
    return FuelLogModel(
      id: json['id']?.toString() ?? '',
      vehiculoId: json['vehiculo_id']?.toString() ?? '',
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
      kmsActuales: ((json['kms_actuales'] ?? 0) as num).toDouble(),
      montoCop: ((json['monto_cop'] ?? 0) as num).toDouble(),
      galones: ((json['galones'] ?? 0) as num).toDouble(),
      precioPorGalon: ((json['precio_por_galon'] ?? 0) as num).toDouble(),
      esTanqueLleno: json['es_tanque_lleno'] ?? true,
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehiculo_id': vehiculoId,
      'fecha': fecha.toIso8601String(),
      'kms_actuales': kmsActuales,
      'monto_cop': montoCop,
      'galones': galones,
      'precio_por_galon': precioPorGalon,
      'es_tanque_lleno': esTanqueLleno,
      'notas': notas,
    };
  }
}
