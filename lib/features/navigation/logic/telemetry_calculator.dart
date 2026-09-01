import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/logic/vehicle_performance_logic.dart';

/// Lógica pura para cálculos de telemetría GPS.
/// Desacoplada de Flutter UI para facilitar el testeo y la precisión.
class TelemetryCalculator {
  
  /// Calcula la distancia recorrida entre dos puntos con filtro de ruido y estado de detención.
  /// Retorna la distancia en kilómetros.
  static double calculateIncrementalDistance(
    LatLng oldPos, 
    LatLng newPos, {
    bool isStationary = false,
    double? speedMs,
  }) {
    // Si el vehículo está detenido (< 0.8 m/s o marcado como estacionario), no acumular distancia
    if (isStationary || (speedMs != null && speedMs < 0.8)) {
      return 0.0;
    }

    final distMeters = Geolocator.distanceBetween(
      oldPos.latitude, 
      oldPos.longitude, 
      newPos.latitude, 
      newPos.longitude
    );

    // Filtro de ruido (jitter): Ignorar saltos menores a 3m (vehículo detenido o temblor)
    // o saltos mayores a 5000m en un solo tick (glitch extremo de GPS/red).
    if (distMeters < 3.5 || distMeters > 5000) return 0.0;
    
    return distMeters / 1000.0;
  }

  /// Calcula la velocidad promedio basada en muestras puntuales de velocidad acumuladas.
  static double calculateAverageSpeed(double accumulatedSpeed, int speedSamples) {
    if (speedSamples <= 0) return 0.0;
    return accumulatedSpeed / speedSamples;
  }

  /// Calcula la velocidad promedio cinemática basada en distancia total recorrida y tiempo transcurrido (en segundos).
  static double calculateKinematicAverageSpeed({
    required double distanceKm,
    required int durationSeconds,
    double fallbackSpeedKmH = 0.0,
  }) {
    if (durationSeconds > 5 && distanceKm > 0.01) {
      final hours = durationSeconds / 3600.0;
      final speed = distanceKm / hours;
      // Limitar a valores físicamente plausibles (0 a 350 km/h)
      return speed.clamp(0.0, 350.0);
    }
    return fallbackSpeedKmH;
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
  static List<LatLng> optimizeRoutePoints(
    List<LatLng> currentPoints, 
    LatLng newPoint, {
    bool isStationary = false,
    double minDistanceThresholdMeters = 4.0,
  }) {
    final updated = List<LatLng>.from(currentPoints);
    if (updated.isEmpty) {
      updated.add(newPoint);
      return updated;
    }

    // Si está estacionario y ya tenemos al menos un punto, no agregar puntos de oscilación
    if (isStationary) {
      return updated;
    }

    final lastPoint = updated.last;
    final distMeters = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      newPoint.latitude,
      newPoint.longitude,
    );

    // Solo agregar el nuevo punto a la polilínea si el desplazamiento es >= umbral configurado
    if (distMeters >= minDistanceThresholdMeters) {
      updated.add(newPoint);
      if (updated.length > 5000) {
        updated.removeAt(0);
      }
    }
    return updated;
  }
}

