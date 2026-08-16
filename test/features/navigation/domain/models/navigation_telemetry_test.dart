import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_auto_guide/features/navigation/domain/models/navigation_telemetry.dart';

void main() {
  group('NavigationTelemetry', () {
    test('starts empty', () {
      final telemetry = NavigationTelemetry.empty();
      expect(telemetry.currentPos, isNull);
      expect(telemetry.travelledPoints, isEmpty);
      expect(telemetry.distanceKm, 0.0);
      expect(telemetry.maxSpeedKmH, 0.0);
      expect(telemetry.averageSpeedKmH, 0.0);
      expect(telemetry.startTime, isNull);
      expect(telemetry.fuelConsumptionGal, 0.0);
      expect(telemetry.estimatedCost, 0.0);
    });

    test('copyWith overrides only the provided fields', () {
      const origin = LatLng(6.2442, -75.5812);
      final start = DateTime.utc(2024, 3, 1, 7);
      final base = NavigationTelemetry.empty().copyWith(
        currentPos: origin,
        startTime: start,
        distanceKm: 10,
      );

      final updated = base.copyWith(distanceKm: 25, maxSpeedKmH: 88);

      expect(updated.distanceKm, 25.0);
      expect(updated.maxSpeedKmH, 88.0);
      expect(updated.currentPos, origin);
      expect(updated.startTime, start);
      expect(updated.averageSpeedKmH, 0.0);
    });

    test('copyWith without arguments keeps every value', () {
      const origin = LatLng(6.2442, -75.5812);
      final base = NavigationTelemetry(
        currentPos: origin,
        travelledPoints: const [origin],
        distanceKm: 12.5,
        maxSpeedKmH: 95,
        averageSpeedKmH: 40,
        startTime: DateTime.utc(2024, 3, 1, 7),
        fuelConsumptionGal: 0.5,
        estimatedCost: 7750,
      );

      final copy = base.copyWith();

      expect(copy.currentPos, base.currentPos);
      expect(copy.travelledPoints, base.travelledPoints);
      expect(copy.distanceKm, base.distanceKm);
      expect(copy.maxSpeedKmH, base.maxSpeedKmH);
      expect(copy.averageSpeedKmH, base.averageSpeedKmH);
      expect(copy.startTime, base.startTime);
      expect(copy.fuelConsumptionGal, base.fuelConsumptionGal);
      expect(copy.estimatedCost, base.estimatedCost);
    });
  });

  group('TripStats', () {
    test('holds the summary of a finished trip', () {
      const origin = LatLng(6.2442, -75.5812);
      final stats = TripStats(
        totalDistanceKm: 42.5,
        duration: const Duration(minutes: 55),
        topSpeedKmH: 110,
        avgSpeedKmH: 46,
        fuelConsumedGal: 0.31,
        totalCost: 4805,
        route: const [origin],
      );

      expect(stats.totalDistanceKm, 42.5);
      expect(stats.duration.inMinutes, 55);
      expect(stats.topSpeedKmH, 110);
      expect(stats.avgSpeedKmH, 46);
      expect(stats.fuelConsumedGal, 0.31);
      expect(stats.totalCost, 4805);
      expect(stats.route, [origin]);
    });
  });
}
