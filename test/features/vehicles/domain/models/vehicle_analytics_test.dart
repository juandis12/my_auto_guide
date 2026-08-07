import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/core/logic/vehicle_ai_logic.dart';
import 'package:my_auto_guide/features/vehicles/domain/models/vehicle_analytics.dart';

void main() {
  group('VehicleAnalytics.fromMap', () {
    test('maps the analysis returned by VehicleAILogic', () {
      final analytics = VehicleAnalytics.fromMap(
        VehicleAILogic.analyzeJourneyPatterns(
          routeHistory: const [
            {'distancia_km': 200},
            {'distancia_km': 200},
          ],
          modelName: 'MT 15',
        ),
      );

      expect(analytics.intensity, 'Alta');
      expect(analytics.consistency, 'Alta');
      expect(analytics.healthImpact, -2.5);
      expect(analytics.careScore, 85.0);
      expect(analytics.avgDailyKm, closeTo(400 / 7, 0.0001));
      expect(analytics.advice, isNotEmpty);
    });

    test('parses numeric values coming as strings or integers', () {
      final analytics = VehicleAnalytics.fromMap(const {
        'healthImpact': '1.5',
        'careScore': 90,
        'avgDailyKm': '12.25',
      });

      expect(analytics.healthImpact, 1.5);
      expect(analytics.careScore, 90.0);
      expect(analytics.avgDailyKm, 12.25);
    });

    test('applies defaults for missing or unparsable values', () {
      final analytics = VehicleAnalytics.fromMap(const {
        'healthImpact': 'no-es-un-numero',
      });

      expect(analytics.intensity, 'Baja');
      expect(analytics.consistency, 'Pendiente');
      expect(analytics.advice, '');
      expect(analytics.healthImpact, 0.0);
      expect(analytics.careScore, 0.0);
      expect(analytics.avgDailyKm, 0.0);
    });
  });

  group('VehicleAnalytics.empty', () {
    test('describes a vehicle without enough data yet', () {
      final analytics = VehicleAnalytics.empty();
      expect(analytics.intensity, 'Baja');
      expect(analytics.consistency, 'Pendiente');
      expect(analytics.careScore, 100.0);
      expect(analytics.avgDailyKm, 0.0);
      expect(analytics.advice, isNotEmpty);
    });
  });
}
