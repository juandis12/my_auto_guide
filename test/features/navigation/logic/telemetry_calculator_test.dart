import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_auto_guide/features/navigation/logic/telemetry_calculator.dart';

void main() {
  const origin = LatLng(6.2442, -75.5812); // Medellín

  group('TelemetryCalculator.calculateIncrementalDistance', () {
    test('returns the distance in kilometres for a plausible movement', () {
      const oneKmNorth = LatLng(6.2532, -75.5812);
      final distance = TelemetryCalculator.calculateIncrementalDistance(origin, oneKmNorth);
      expect(distance, closeTo(1.0, 0.05));
    });

    test('filters out GPS jitter below 3 metres', () {
      const jitter = LatLng(6.24421, -75.5812);
      expect(TelemetryCalculator.calculateIncrementalDistance(origin, jitter), 0.0);
      expect(TelemetryCalculator.calculateIncrementalDistance(origin, origin), 0.0);
    });

    test('filters out impossible jumps above 5 km', () {
      const bogota = LatLng(4.7110, -74.0721);
      expect(TelemetryCalculator.calculateIncrementalDistance(origin, bogota), 0.0);
    });
  });

  group('TelemetryCalculator.calculateAverageSpeed', () {
    test('divides the accumulated speed by the number of samples', () {
      expect(TelemetryCalculator.calculateAverageSpeed(150, 3), 50.0);
    });

    test('returns 0 when there is no sample', () {
      expect(TelemetryCalculator.calculateAverageSpeed(150, 0), 0.0);
      expect(TelemetryCalculator.calculateAverageSpeed(150, -1), 0.0);
    });
  });

  group('TelemetryCalculator.estimateImpact', () {
    test('estimates gallons and cost from the current telemetry', () {
      final impact = TelemetryCalculator.estimateImpact(
        distanceKm: 135,
        avgSpeedKmH: 70,
        vehicleModel: 'MT 15',
        isCar: false,
      );
      expect(impact['gallons'], closeTo(1.0, 0.0001));
      expect(impact['cost'], closeTo(15500, 0.0001));
    });

    test('a car consumes more than a small motorcycle over the same route', () {
      final moto = TelemetryCalculator.estimateImpact(
        distanceKm: 100,
        avgSpeedKmH: 60,
        vehicleModel: 'MT 15',
        isCar: false,
      );
      final car = TelemetryCalculator.estimateImpact(
        distanceKm: 100,
        avgSpeedKmH: 60,
        vehicleModel: 'Corolla',
        isCar: true,
      );
      expect(car['gallons']!, greaterThan(moto['gallons']!));
    });
  });

  group('TelemetryCalculator.optimizeRoutePoints', () {
    test('appends a new point to the route', () {
      const next = LatLng(6.2532, -75.5812);
      final points = TelemetryCalculator.optimizeRoutePoints(const [origin], next);
      expect(points, [origin, next]);
    });

    test('does not duplicate the last point', () {
      final points = TelemetryCalculator.optimizeRoutePoints(const [origin], origin);
      expect(points, [origin]);
    });

    test('does not mutate the received list', () {
      final original = <LatLng>[origin];
      TelemetryCalculator.optimizeRoutePoints(original, const LatLng(6.2532, -75.5812));
      expect(original, [origin]);
    });

    test('keeps at most 5000 points to avoid running out of memory', () {
      final full = List<LatLng>.generate(5000, (i) => LatLng(6.0 + i / 100000, -75.0));
      const next = LatLng(7.0, -75.0);
      final points = TelemetryCalculator.optimizeRoutePoints(full, next);
      expect(points.length, 5000);
      expect(points.first, full[1]);
      expect(points.last, next);
    });
  });
}
