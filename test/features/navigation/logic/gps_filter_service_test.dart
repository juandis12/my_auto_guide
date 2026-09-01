import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_auto_guide/features/navigation/logic/gps_filter_service.dart';

void main() {
  group('KalmanLatLong Filter', () {
    test('initializes with the first raw measurement', () {
      final kalman = KalmanLatLong();
      final now = DateTime.now();
      final pos = kalman.process(
        latMeasurement: 4.6097,
        lngMeasurement: -74.0817,
        accuracy: 5.0,
        timestamp: now,
      );

      expect(pos.latitude, closeTo(4.6097, 0.00001));
      expect(pos.longitude, closeTo(-74.0817, 0.00001));
      expect(kalman.isInitialized, isTrue);
    });

    test('smooths noisy measurements towards the kinematic trajectory', () {
      final kalman = KalmanLatLong(processNoise: 3.0);
      var time = DateTime.now();

      // Punto base en Bogotá
      kalman.process(latMeasurement: 4.60970, lngMeasurement: -74.08170, accuracy: 4.0, timestamp: time);

      // Simular oscilación artificial por ruido de antena (desvío lateral de 15m)
      time = time.add(const Duration(seconds: 1));
      final noisyPoint = kalman.process(
        latMeasurement: 4.60990, // ~22m al norte
        lngMeasurement: -74.08170,
        accuracy: 15.0, // Baja confianza
        timestamp: time,
      );

      // El filtro de Kalman debe amortiguar el salto debido a la alta incertidumbre
      expect(noisyPoint.latitude, lessThan(4.60990));
      expect(noisyPoint.latitude, greaterThan(4.60970));
    });
  });

  group('GpsFilterService', () {
    late GpsFilterService service;

    setUp(() {
      service = GpsFilterService(
        maxAccuracyThreshold: 20.0,
        minMovingSpeedMs: 0.8,
        maxPlausibleSpeedMs: 55.0,
        snapToRouteMaxDistance: 25.0,
      );
    });

    test('accepts initial point even if accuracy is moderate', () {
      final res = service.filterPoint(
        lat: 4.6097,
        lng: -74.0817,
        accuracy: 12.0,
        speedMs: 5.0,
        timestamp: DateTime.now(),
      );

      expect(res, isNotNull);
      expect(res!.position.latitude, closeTo(4.6097, 0.0001));
      expect(res.isStationary, isFalse);
    });

    test('discards points with accuracy worse than maxAccuracyThreshold when initialized', () {
      final now = DateTime.now();
      service.filterPoint(lat: 4.6097, lng: -74.0817, accuracy: 5.0, speedMs: 5.0, timestamp: now);

      // Siguiente punto con 35m de error satelital (degradación)
      final degraded = service.filterPoint(
        lat: 4.6105,
        lng: -74.0817,
        accuracy: 35.0,
        speedMs: 5.0,
        timestamp: now.add(const Duration(seconds: 1)),
      );

      expect(degraded, isNull);
    });

    test('discards impossible speed jumps (multipath/teleport anomaly)', () {
      final now = DateTime.now();
      service.filterPoint(lat: 4.6097, lng: -74.0817, accuracy: 5.0, speedMs: 10.0, timestamp: now);

      // 1 segundo después, salto de 5 km (Bogotá Norte) con baja precisión
      final teleport = service.filterPoint(
        lat: 4.6547,
        lng: -74.0817,
        accuracy: 15.0,
        speedMs: 10.0,
        timestamp: now.add(const Duration(seconds: 1)),
      );

      expect(teleport, isNull);
    });

    test('detects stationary state and suppresses drift when speed < 0.8 m/s', () {
      var time = DateTime.now();
      service.filterPoint(lat: 4.6097, lng: -74.0817, accuracy: 4.0, speedMs: 0.0, timestamp: time);

      // Simular semáforo en rojo: pequeñas oscilaciones de antena
      time = time.add(const Duration(seconds: 2));
      final stationary1 = service.filterPoint(
        lat: 4.60972,
        lng: -74.08172,
        accuracy: 6.0,
        speedMs: 0.2, // ~0.7 km/h (ruido)
        timestamp: time,
      );

      expect(stationary1, isNotNull);
      expect(stationary1!.isStationary, isTrue);
      expect(stationary1.speedMs, 0.0);

      time = time.add(const Duration(seconds: 2));
      final stationary2 = service.filterPoint(
        lat: 4.60968,
        lng: -74.08168,
        accuracy: 8.0,
        speedMs: 0.1,
        timestamp: time,
      );

      expect(stationary2, isNotNull);
      expect(stationary2!.isStationary, isTrue);
      // Debe congelar la posición para evitar la telaraña en semáforos
      expect(stationary2.position.latitude, closeTo(stationary1.position.latitude, 0.000001));
    });

    test('Snap-to-Route snaps orthogonal position to street segment within 25m', () {
      // Línea recta este-oeste sobre la Calle 26
      final route = [
        const LatLng(4.6097, -74.0850),
        const LatLng(4.6097, -74.0800),
      ];

      // Posición del GPS desviada 12m al norte (multipath de edificios)
      final snapResult = GpsFilterService.snapToRoute(
        const LatLng(4.6098, -74.0825),
        route,
        maxDistanceMeters: 25.0,
      );

      expect(snapResult.isSnapped, isTrue);
      // La latitud proyectada debe ajustarse exactamente al eje de la calle (4.6097)
      expect(snapResult.position.latitude, closeTo(4.6097, 0.00005));
      expect(snapResult.position.longitude, closeTo(-74.0825, 0.00005));
    });

    test('Snap-to-Route does NOT snap if user is off-route (> 25m detour)', () {
      final route = [
        const LatLng(4.6097, -74.0850),
        const LatLng(4.6097, -74.0800),
      ];

      // Desvío de 80m al norte
      final snapResult = GpsFilterService.snapToRoute(
        const LatLng(4.6105, -74.0825),
        route,
        maxDistanceMeters: 25.0,
      );

      expect(snapResult.isSnapped, isFalse);
      expect(snapResult.position.latitude, closeTo(4.6105, 0.00001));
    });
  });
}
