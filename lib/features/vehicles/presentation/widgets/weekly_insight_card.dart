import 'package:flutter/material.dart';
import '../../../../core/logic/vehicle_health_logic.dart';
import '../../../../core/logic/performance_guard.dart';
import '../../../../core/logic/fuel_efficiency_logic.dart';
import '../../../../core/theme/brand_theme.dart';
import '../../domain/models/weekly_stats.dart';
import '../../domain/models/maintenance_prediction.dart';
import 'ai_insights_panel.dart';
import 'proactive_predictions_card.dart';

class WeeklyInsightCard extends StatelessWidget {
  final double pctCadena, pctFiltro, pctAceite, pctSoat, pctTecno;
  final BrandTheme brandTheme;
  final bool isLoading;
  final List<MaintenancePrediction> predictions;
  final WeeklyStats stats;
  final String modelName;
  final VoidCallback onHistoryTap;

  const WeeklyInsightCard({
    super.key,
    required this.pctCadena,
    required this.pctFiltro,
    required this.pctAceite,
    required this.pctSoat,
    required this.pctTecno,
    required this.brandTheme,
    required this.stats,
    required this.predictions,
    required this.modelName,
    required this.onHistoryTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthIndex = VehicleHealthLogic.calculateHealthIndex(
        pctCadena: pctCadena,
        pctFiltro: pctFiltro,
        pctAceite: pctAceite,
        pctSoat: pctSoat,
        pctTecno: pctTecno);

    final efficiencyScore = stats.aiAnalytics.careScore; // Simplified for now
    final savingsCOP = stats.aiAnalytics.avgDailyKm * 0.1; // Ejemplo

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: brandTheme.primaryColor.withOpacity(0.1)),
          boxShadow: [
            if (!PerformanceGuard().isLowEnd)
              BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
          ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: brandTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.insights_rounded,
                    color: brandTheme.primaryColor, size: 22)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Resumen de los últimos 7 días',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black54)),
                  Text(VehicleHealthLogic.getVehicleStatus(healthIndex),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ])),
            if (isLoading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _StatItem(
                label: 'Distancia',
                value: '${stats.totalKm.toStringAsFixed(1)} km',
                icon: Icons.route_outlined,
                color: Colors.blue),
            _StatItem(
                label: 'Consumo',
                value: '${stats.totalGallons.toStringAsFixed(1)} gal',
                icon: Icons.local_gas_station_rounded,
                color: Colors.orange),
            _StatItem(
                label: 'Gasto',
                value: '\$${(stats.totalCost / 1000).toStringAsFixed(1)}k',
                icon: Icons.payments_rounded,
                color: Colors.green),
          ]),
          const Divider(height: 32),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Icon(Icons.eco_rounded,
                        color: efficiencyScore >= 95
                            ? Colors.green
                            : Colors.orange,
                        size: 16),
                    const SizedBox(width: 6),
                    Text(
                        FuelEfficiencyLogic.getEfficiencyLabel(efficiencyScore),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))
                  ]),
                  const SizedBox(height: 8),
                  Stack(children: [
                    Container(
                        height: 8,
                        decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                        widthFactor: (efficiencyScore / 120).clamp(0.01, 1.0),
                        child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.green.shade300,
                                  Colors.green.shade600
                                ]),
                                borderRadius: BorderRadius.circular(4))))
                  ]),
                ])),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(savingsCOP >= 0 ? 'Ahorro Real' : 'Sobre-costo',
                  style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54)),
              Text(
                  '${savingsCOP >= 0 ? '+' : ''}\$${(savingsCOP / 1000).toStringAsFixed(1)}k',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          savingsCOP >= 0 ? Colors.green : Colors.redAccent)),
            ]),
          ]),
          const Divider(height: 32),
          // --- IA INSIGHTS SECTION ---
          AIInsightsPanel(
            analytics: stats.aiAnalytics,
          ),
          if (predictions.isNotEmpty) ...[
            const Divider(height: 32),
            ProactivePredictionsCard(predictions: predictions)
          ],
          const Divider(height: 32),
          Row(children: [
            Expanded(
                child: Text(VehicleHealthLogic.getWeeklySummary(healthIndex),
                    style: TextStyle(
                        height: 1.4,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87))),
            IconButton(
                onPressed: onHistoryTap,
                icon: Icon(Icons.history_toggle_off_rounded,
                    color: brandTheme.primaryColor)),
          ]),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label,
          style: TextStyle(
              fontSize: 10, color: isDark ? Colors.white54 : Colors.black54))
    ]);
  }
}
