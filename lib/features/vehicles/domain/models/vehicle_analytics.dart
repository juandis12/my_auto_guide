class VehicleAnalytics {
  final String intensity;
  final String consistency;
  final String advice;
  final double healthImpact;
  final double careScore;
  final double avgDailyKm;

  const VehicleAnalytics({
    required this.intensity,
    required this.consistency,
    required this.advice,
    required this.healthImpact,
    required this.careScore,
    required this.avgDailyKm,
  });

  factory VehicleAnalytics.fromMap(Map<String, dynamic> map) {
    return VehicleAnalytics(
      intensity: map['intensity']?.toString() ?? 'Baja',
      consistency: map['consistency']?.toString() ?? 'Pendiente',
      advice: map['advice']?.toString() ?? '',
      healthImpact: _asDouble(map['healthImpact']),
      careScore: _asDouble(map['careScore']),
      avgDailyKm: _asDouble(map['avgDailyKm']),
    );
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static VehicleAnalytics empty() => const VehicleAnalytics(
        intensity: 'Baja',
        consistency: 'Pendiente',
        advice: 'Carga trayectos para activar la IA.',
        healthImpact: 0.0,
        careScore: 100.0,
        avgDailyKm: 0.0,
      );
}
