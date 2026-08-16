import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/logic/vehicle_health_logic.dart';
import '../../../../core/logic/performance_guard.dart';
import '../../../../core/logic/fuel_efficiency_logic.dart';
import '../../../../core/theme/brand_theme.dart';
import '../../../../core/theme/app_apple_theme.dart';
import '../../domain/models/weekly_stats.dart';
import '../../domain/models/maintenance_prediction.dart';
import 'ai_insights_panel.dart';
import 'proactive_predictions_card.dart';

/// Tarjeta de Resumen Semanal e Inteligencia Automotriz con Estilo Apple HIG Glassmorphism
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
      pctTecno: pctTecno,
    );

    final efficiencyScore = stats.aiAnalytics.careScore;
    final savingsCOP = stats.aiAnalytics.avgDailyKm * 0.1;

    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(24),
      fallbackColor: isDark
          ? AppAppleTheme.midnightSurface.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.90),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppAppleTheme.glassBlurSigma,
            sigmaY: AppAppleTheme.glassBlurSigma,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark
                  ? AppAppleTheme.midnightSurface.withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppAppleTheme.electricCyan.withValues(alpha: 0.20)
                    : AppAppleTheme.electricBlue.withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: brandTheme.primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: brandTheme.primaryColor.withValues(alpha: 0.30),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: brandTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de los últimos 7 días',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          Text(
                            VehicleHealthLogic.getVehicleStatus(healthIndex),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(
                      label: 'Distancia',
                      value: '${stats.totalKm.toStringAsFixed(1)} km',
                      icon: Icons.route_outlined,
                      color: AppAppleTheme.electricCyan,
                    ),
                    _StatItem(
                      label: 'Consumo',
                      value: '${stats.totalGallons.toStringAsFixed(1)} gal',
                      icon: Icons.local_gas_station_rounded,
                      color: Colors.orangeAccent,
                    ),
                    _StatItem(
                      label: 'Gasto',
                      value: '\$${(stats.totalCost / 1000).toStringAsFixed(1)}k',
                      icon: Icons.payments_rounded,
                      color: Colors.emerald,
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 0.8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                color: efficiencyScore >= 95 ? Colors.emerald : Colors.orangeAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                FuelEfficiencyLogic.getEfficiencyLabel(efficiencyScore),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: (efficiencyScore / 120).clamp(0.01, 1.0),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.emerald.shade300,
                                        Colors.emerald.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          savingsCOP >= 0 ? 'Ahorro Real' : 'Sobre-costo',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        Text(
                          '${savingsCOP >= 0 ? '+' : ''}\$${(savingsCOP / 1000).toStringAsFixed(1)}k',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: savingsCOP >= 0 ? Colors.emerald : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32, thickness: 0.8),
                AIInsightsPanel(
                  analytics: stats.aiAnalytics,
                ),
                if (predictions.isNotEmpty) ...[
                  const Divider(height: 32, thickness: 0.8),
                  ProactivePredictionsCard(predictions: predictions)
                ],
                const Divider(height: 32, thickness: 0.8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        VehicleHealthLogic.getWeeklySummary(healthIndex),
                        style: TextStyle(
                          height: 1.4,
                          fontSize: 13,
                          color: isDark ? Colors.white.withValues(alpha: 0.80) : Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onHistoryTap,
                      icon: Icon(
                        Icons.history_toggle_off_rounded,
                        color: brandTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
