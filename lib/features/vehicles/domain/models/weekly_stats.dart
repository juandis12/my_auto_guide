import 'vehicle_analytics.dart';

class WeeklyStats {
  final double totalKm;
  final double totalGallons;
  final double totalCost;
  final int routeCount;
  final List<Map<String, dynamic>> routeHistory;
  final VehicleAnalytics aiAnalytics;

  const WeeklyStats({
    required this.totalKm,
    required this.totalGallons,
    required this.totalCost,
    required this.routeCount,
    required this.routeHistory,
    required this.aiAnalytics,
  });

  factory WeeklyStats.empty() => WeeklyStats(
        totalKm: 0.0,
        totalGallons: 0.0,
        totalCost: 0.0,
        routeCount: 0,
        routeHistory: const [],
        aiAnalytics: VehicleAnalytics.empty(),
      );

  factory WeeklyStats.fromData({
    required double km,
    required double gallons,
    required double cost,
    required int count,
    required List<Map<String, dynamic>> history,
    required VehicleAnalytics analytics,
  }) {
    return WeeklyStats(
      totalKm: km,
      totalGallons: gallons,
      totalCost: cost,
      routeCount: count,
      routeHistory: history,
      aiAnalytics: analytics,
    );
  }
}
