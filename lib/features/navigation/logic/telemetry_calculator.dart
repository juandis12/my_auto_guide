import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/logic/vehicle_performance_logic.dart';

/// Lógica pura para cálculos de telemetría GPS.
/// Desacoplada de Flutter UI para facilitar el testeo y la precisión.
class TelemetryCalculator {
  
  /// Calcula la distancia recorrida entre dos puntos con filtro de ruido.
  /// Retorna la distancia en kilómetros.
  static double calculateIncrementalDistance(LatLng oldPos, LatLng newPos) {
    final distMeters = Geolocator.distanceBetween(
      oldPos.latitude, 
      oldPos.longitude, 
      newPos.latitude, 
      newPos.longitude
    );

    // Filtro de ruido (jitter): Ignorar saltos menores a 3m o mayores a 400m en un intervalo corto.
    // Esto previene que el GPS sume km mientras el vehículo está detenido o por glitches de red.
    if (distMeters < 3 || distMeters > 400) return 0.0;
    
    return distMeters / 1000.0;
  }

  /// Calcula la velocidad promedio basada en la suma de velocidades y puntos detectados.
  static double calculateAverageSpeed(double speedSum, int pointsCount) {
    if (pointsCount <= 0) return 0.0;
    return speedSum / pointsCount;
  }

  /// Estima el consumo y costo basado en la telemetría actual.
  static Map<String, double> estimateImpact({
    required double distanceKm,
    required double avgSpeedKmH,
    required String vehicleModel,
    required bool isCar,
  }) {
    final gallons = VehiclePerformanceLogic.estimateFuelConsumption(
      distanceKm, 
      vehicleModel,
      isCar: isCar,
      avgSpeedKmH: avgSpeedKmH
    );
    final cost = VehiclePerformanceLogic.estimateFuelCost(gallons);
    
    return {
      'gallons': gallons,
      'cost': cost,
    };
  }

  /// Limita la cantidad de puntos en memoria para evitar el temido "App Crash" por OOM.
  /// Mantiene los últimos 5000 puntos (suficiente para rutas largas).
  static List<LatLng> optimizeRoutePoints(List<LatLng> currentPoints, LatLng newPoint) {
    final updated = List<LatLng>.from(currentPoints);
    if (updated.isEmpty || updated.last != newPoint) {
      updated.add(newPoint);
      if (updated.length > 5000) {
        updated.removeAt(0);
      }
    }
    return updated;
  }
}
