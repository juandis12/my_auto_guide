import 'package:latlong2/latlong.dart';

/// Modelo inmutable que representa el estado de telemetría de un viaje en curso.
class NavigationTelemetry {
  final LatLng? currentPos;
  final List<LatLng> travelledPoints;
  final double distanceKm;
  final double maxSpeedKmH;
  final double averageSpeedKmH;
  final DateTime? startTime;
  final double fuelConsumptionGal;
  final double estimatedCost;

  const NavigationTelemetry({
    this.currentPos,
    this.travelledPoints = const [],
    this.distanceKm = 0.0,
    this.maxSpeedKmH = 0.0,
    this.averageSpeedKmH = 0.0,
    this.startTime,
    this.fuelConsumptionGal = 0.0,
    this.estimatedCost = 0.0,
  });

  NavigationTelemetry copyWith({
    LatLng? currentPos,
    List<LatLng>? travelledPoints,
    double? distanceKm,
    double? maxSpeedKmH,
    double? averageSpeedKmH,
    DateTime? startTime,
    double? fuelConsumptionGal,
    double? estimatedCost,
  }) {
    return NavigationTelemetry(
      currentPos: currentPos ?? this.currentPos,
      travelledPoints: travelledPoints ?? this.travelledPoints,
      distanceKm: distanceKm ?? this.distanceKm,
      maxSpeedKmH: maxSpeedKmH ?? this.maxSpeedKmH,
      averageSpeedKmH: averageSpeedKmH ?? this.averageSpeedKmH,
      startTime: startTime ?? this.startTime,
      fuelConsumptionGal: fuelConsumptionGal ?? this.fuelConsumptionGal,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  factory NavigationTelemetry.empty() => const NavigationTelemetry();
}

/// Estadísticas finales de un viaje completado.
class TripStats {
  final double totalDistanceKm;
  final Duration duration;
  final double topSpeedKmH;
  final double avgSpeedKmH;
  final double fuelConsumedGal;
  final double totalCost;
  final List<LatLng> route;

  TripStats({
    required this.totalDistanceKm,
    required this.duration,
    required this.topSpeedKmH,
    required this.avgSpeedKmH,
    required this.fuelConsumedGal,
    required this.totalCost,
    required this.route,
  });
}
