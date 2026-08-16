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

    // Filtro de ruido (jitter): Ignorar saltos menores a 3m (vehículo detenido)
    // o saltos mayores a 5000m en un solo tick (glitch extremo de GPS/red).
    if (distMeters < 3 || distMeters > 5000) return 0.0;
    
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

  /// Limita y filtra los puntos de la ruta para generar una línea suave (Polyline)
  /// e impedir zigzags o distorsiones por temblor de GPS cuando el vehículo se detiene.
  static List<LatLng> optimizeRoutePoints(List<LatLng> currentPoints, LatLng newPoint) {
    final updated = List<LatLng>.from(currentPoints);
    if (updated.isEmpty) {
      updated.add(newPoint);
      return updated;
    }

    final lastPoint = updated.last;
    final distMeters = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      newPoint.latitude,
      newPoint.longitude,
    );

    // Solo agregar el nuevo punto a la polilínea si el desplazamiento es >= 4.0 metros
    if (distMeters >= 4.0) {
      updated.add(newPoint);
      if (updated.length > 5000) {
        updated.removeAt(0);
      }
    }
    return updated;
  }
}
