import 'package:flutter_test/flutter_test.dart';
import 'package:my_auto_guide/features/vehicles/domain/models/vehicle_analytics.dart';
import 'package:my_auto_guide/features/vehicles/domain/models/weekly_stats.dart';

void main() {
  group('WeeklyStats.empty', () {
    test('starts every counter at zero with the empty analytics', () {
      final stats = WeeklyStats.empty();
      expect(stats.totalKm, 0.0);
      expect(stats.totalGallons, 0.0);
      expect(stats.totalCost, 0.0);
      expect(stats.routeCount, 0);
      expect(stats.routeHistory, isEmpty);
      expect(stats.aiAnalytics.intensity, VehicleAnalytics.empty().intensity);
      expect(stats.aiAnalytics.careScore, 100.0);
    });
  });

  group('WeeklyStats.fromData', () {
    test('keeps the aggregated weekly values', () {
      final history = [
        {'distancia_km': 40.0},
        {'distancia_km': 60.0},
      ];
      final analytics = VehicleAnalytics.fromMap(const {
        'intensity': 'Media',
        'consistency': 'Alta',
        'advice': 'Conducción estable',
        'healthImpact': 1.0,
        'careScore': 100.0,
        'avgDailyKm': 14.3,
      });

      final stats = WeeklyStats.fromData(
        km: 100,
        gallons: 0.74,
        cost: 11470,
        count: 2,
        history: history,
        analytics: analytics,
      );

      expect(stats.totalKm, 100.0);
      expect(stats.totalGallons, 0.74);
      expect(stats.totalCost, 11470);
      expect(stats.routeCount, 2);
      expect(stats.routeHistory, history);
      expect(stats.aiAnalytics.intensity, 'Media');
      expect(stats.aiAnalytics.avgDailyKm, 14.3);
    });
  });
}
