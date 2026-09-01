import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Resultado del procesamiento y filtrado de un punto GPS.
class GpsFilterResult {
  /// Posición final optimizada (suavizada y proyectada si aplica).
  final LatLng position;

  /// Posición cruda original entregada por el sensor satelital.
  final LatLng rawPosition;

  /// Velocidad en m/s (suavizada o validada).
  final double speedMs;

  /// Rumbo/orientación en grados [0..360].
  final double bearing;

  /// Precisión en metros reportada por el sensor.
  final double accuracy;

  /// Indica si el vehículo está considerado detenido (< 0.8 m/s).
  final bool isStationary;

  /// Indica si el punto fue alineado al eje vial mediante Snap-to-Route.
  final bool isSnapped;

  const GpsFilterResult({
    required this.position,
    required this.rawPosition,
    required this.speedMs,
    required this.bearing,
    required this.accuracy,
    required this.isStationary,
    required this.isSnapped,
  });

  double get speedKmH => speedMs * 3.6;
}

/// Implementación 1D/2D de un Filtro de Kalman adaptativo para coordenadas geográficas.
class KalmanLatLong {
  final double processNoise; // Q: Incertidumbre del proceso cinemático
  double _variance = -1.0;   // P: Covarianza de error estimada
  double _lat = 0.0;
  double _lng = 0.0;
  DateTime? _lastTimestamp;

  KalmanLatLong({this.processNoise = 3.0}); // ~3.0 metros de varianza de aceleración

  bool get isInitialized => _variance > 0;

  LatLng? get currentEstimate => isInitialized ? LatLng(_lat, _lng) : null;

  void reset() {
    _variance = -1.0;
    _lat = 0.0;
    _lng = 0.0;
    _lastTimestamp = null;
  }

  /// Procesa una nueva medición GPS $(lat, lng)$ con una precisión $accuracy$ en metros.
  LatLng process({
    required double latMeasurement,
    required double lngMeasurement,
    required double accuracy,
    required DateTime timestamp,
  }) {
    // Si la precisión es 0 o irrealmente baja, usar un valor piso seguro de 3m
    final double measurementNoise = math.max(accuracy, 3.0);
    final double r = measurementNoise * measurementNoise;

    if (!isInitialized) {
      _lat = latMeasurement;
      _lng = lngMeasurement;
      _variance = r;
      _lastTimestamp = timestamp;
      return LatLng(_lat, _lng);
    }

    // Paso 1: Predicción con base en tiempo transcurrido (Delta t)
    final double dtSeconds = _lastTimestamp != null
        ? math.max(timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0, 0.1)
        : 1.0;
    _lastTimestamp = timestamp;

    // Aumentar incertidumbre con el tiempo transcurrido
    _variance += (processNoise * processNoise) * dtSeconds;

    // Paso 2: Ganancia de Kalman K = P / (P + R)
    final double k = _variance / (_variance + r);

    // Paso 3: Actualización de estado
    _lat += k * (latMeasurement - _lat);
    _lng += k * (lngMeasurement - _lng);

    // Paso 4: Actualización de covarianza P = (1 - K) * P
    _variance = (1.0 - k) * _variance;

    return LatLng(_lat, _lng);
  }
}

/// Servicio integral de filtrado, saneamiento cinemático y Map-Matching para navegación GPS.
class GpsFilterService {
  final KalmanLatLong _kalman = KalmanLatLong(processNoise: 3.0);

  /// Umbral máximo de imprecisión permitido para puntos en movimiento (metros).
  final double maxAccuracyThreshold;

  /// Velocidad mínima para considerar que el vehículo está en movimiento (m/s).
  /// 0.8 m/s = ~2.88 km/h.
  final double minMovingSpeedMs;

  /// Velocidad máxima plausible para un vehículo (m/s) para descartar saltos satelitales.
  /// 55.0 m/s = ~198 km/h.
  final double maxPlausibleSpeedMs;

  /// Distancia máxima de atracción ortogonal para Snap-to-Route (metros).
  final double snapToRouteMaxDistance;

  LatLng? _lastFilteredPosition;
  DateTime? _lastTimestamp;
  double _lastBearing = 0.0;
  int _consecutiveStationaryTicks = 0;

  GpsFilterService({
    this.maxAccuracyThreshold = 20.0,
    this.minMovingSpeedMs = 0.8,
    this.maxPlausibleSpeedMs = 55.0,
    this.snapToRouteMaxDistance = 25.0,
  });

  void reset() {
    _kalman.reset();
    _lastFilteredPosition = null;
    _lastTimestamp = null;
    _lastBearing = 0.0;
    _consecutiveStationaryTicks = 0;
  }

  /// Filtra y sanea una lectura cruda del GPS.
  /// Retorna un `GpsFilterResult` o null si el punto fue descartado por ruido severo.
  GpsFilterResult? filterPoint({
    required double lat,
    required double lng,
    required double accuracy,
    required double speedMs,
    double? heading,
    DateTime? timestamp,
    List<LatLng>? activeRoutePoints,
  }) {
    final now = timestamp ?? DateTime.now();
    final rawPos = LatLng(lat, lng);

    // 1. RECHAZO DE PRECISIÓN DEGRADADA
    // Si la imprecisión satelital es > maxAccuracyThreshold (ej. 20m) y ya tenemos posición previa,
    // descartamos la muestra cruda para evitar desviaciones laterales hacia edificios.
    if (_lastFilteredPosition != null && accuracy > maxAccuracyThreshold) {
      return null;
    }

    // 2. FILTRADO DE ANOMALÍAS CINEMÁTICAS (TELEPORT JUMP)
    if (_lastFilteredPosition != null && _lastTimestamp != null) {
      final dt = math.max(now.difference(_lastTimestamp!).inMilliseconds / 1000.0, 0.1);
      final distMeters = Geolocator.distanceBetween(
        _lastFilteredPosition!.latitude,
        _lastFilteredPosition!.longitude,
        lat,
        lng,
      );
      final calculatedSpeedMs = distMeters / dt;

      // Si la velocidad calculada supera el límite físico y la precisión no es perfecta, rechazar
      if (calculatedSpeedMs > maxPlausibleSpeedMs && accuracy > 8.0) {
        return null;
      }
    }

    // 3. DETECCIÓN DE ESTADO ESTACIONARIO (SEMÁFORO / PARQUEO)
    final bool isStationary = speedMs < minMovingSpeedMs;
    if (isStationary) {
      _consecutiveStationaryTicks++;
    } else {
      _consecutiveStationaryTicks = 0;
    }

    // 4. SUAVIZADO KALMAN
    LatLng kalmanPos;
    if (isStationary && _lastFilteredPosition != null && _consecutiveStationaryTicks > 1) {
      // Si el vehículo está detenido, congelamos la posición previa para eliminar la deriva (drift)
      kalmanPos = _lastFilteredPosition!;
    } else {
      kalmanPos = _kalman.process(
        latMeasurement: lat,
        lngMeasurement: lng,
        accuracy: accuracy,
        timestamp: now,
      );
    }

    // 5. CÁLCULO / SUAVIZADO DE BEARING (RUMBO)
    double bearing = heading ?? 0.0;
    if ((heading == null || heading <= 0) && _lastFilteredPosition != null && !isStationary) {
      bearing = Geolocator.bearingBetween(
        _lastFilteredPosition!.latitude,
        _lastFilteredPosition!.longitude,
        kalmanPos.latitude,
        kalmanPos.longitude,
      );
      if (bearing < 0) bearing += 360.0;
    } else if (heading != null && heading > 0) {
      bearing = heading;
    } else {
      bearing = _lastBearing;
    }
    _lastBearing = bearing;

    // 6. MAP-MATCHING (SNAP-TO-ROUTE)
    LatLng finalPosition = kalmanPos;
    bool isSnapped = false;

    if (activeRoutePoints != null && activeRoutePoints.length >= 2) {
      final snapResult = snapToRoute(kalmanPos, activeRoutePoints, maxDistanceMeters: snapToRouteMaxDistance);
      finalPosition = snapResult.position;
      isSnapped = snapResult.isSnapped;
    }

    _lastFilteredPosition = finalPosition;
    _lastTimestamp = now;

    return GpsFilterResult(
      position: finalPosition,
      rawPosition: rawPos,
      speedMs: isStationary ? 0.0 : speedMs,
      bearing: bearing,
      accuracy: accuracy,
      isStationary: isStationary,
      isSnapped: isSnapped,
    );
  }

  /// Proyecta ortogonalmente un punto geográfico sobre la polilínea vial más cercana.
  /// Si la distancia al segmento más cercano es <= [maxDistanceMeters], devuelve el punto proyectado.
  static ({LatLng position, bool isSnapped, double distanceToSegment}) snapToRoute(
    LatLng point,
    List<LatLng> routePoints, {
    double maxDistanceMeters = 25.0,
  }) {
    if (routePoints.length < 2) {
      return (position: point, isSnapped: false, distanceToSegment: 0.0);
    }

    double minDistance = double.infinity;
    LatLng closestProjectedPoint = point;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final p1 = routePoints[i];
      final p2 = routePoints[i + 1];

      final proj = _projectPointOnSegment(point, p1, p2);
      final dist = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        proj.latitude,
        proj.longitude,
      );

      if (dist < minDistance) {
        minDistance = dist;
        closestProjectedPoint = proj;
      }
    }

    if (minDistance <= maxDistanceMeters) {
      return (position: closestProjectedPoint, isSnapped: true, distanceToSegment: minDistance);
    }

    // Si está a más de maxDistanceMeters (desvío de ruta), no forzar snap
    return (position: point, isSnapped: false, distanceToSegment: minDistance);
  }

  /// Proyección ortogonal de un punto P sobre el segmento [A, B]
  static LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    // Proyección local plana equirrectangular centrada en A
    final double latRad = a.latitude * (math.pi / 180.0);
    final double cosLat = math.cos(latRad);

    // Vector AB en metros aproximados
    final double dx = (b.longitude - a.longitude) * 111320.0 * cosLat;
    final double dy = (b.latitude - a.latitude) * 110540.0;

    // Vector AP en metros aproximados
    final double px = (p.longitude - a.longitude) * 111320.0 * cosLat;
    final double py = (p.latitude - a.latitude) * 110540.0;

    final double segmentLenSq = (dx * dx) + (dy * dy);
    if (segmentLenSq < 0.0001) return a; // Segmento degenerado

    // Factor t de proyección escalar ortogonal
    double t = (px * dx + py * dy) / segmentLenSq;
    t = t.clamp(0.0, 1.0); // Restringir al segmento entre A y B

    final double projLat = a.latitude + t * (b.latitude - a.latitude);
    final double projLng = a.longitude + t * (b.longitude - a.longitude);

    return LatLng(projLat, projLng);
  }
}
