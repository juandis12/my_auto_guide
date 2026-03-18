import 'package:flutter/material.dart';
import '../../../../core/logic/vehicle_health_logic.dart';
import '../../../../core/logic/performance_guard.dart';
import '../../../../core/theme/brand_theme.dart';

import '../../domain/models/weekly_stats.dart';

class AchievementsCard extends StatelessWidget {
  final WeeklyStats stats;
  final double pctCadena, pctFiltro, pctAceite, pctSoat, pctTecno;
  final BrandTheme brandTheme;
  final bool documentsComplete;
  final String modelName;

  const AchievementsCard({
    super.key,
    required this.stats,
    required this.pctCadena,
    required this.pctFiltro,
    required this.pctAceite,
    required this.pctSoat,
    required this.pctTecno,
    required this.brandTheme,
    required this.documentsComplete,
    required this.modelName,
  });

  @override
  Widget build(BuildContext context) {
    final healthIndex = VehicleHealthLogic.calculateHealthIndex(
      pctCadena: pctCadena,
      pctFiltro: pctFiltro,
      pctAceite: pctAceite,
      pctSoat: pctSoat,
      pctTecno: pctTecno,
    );
    final level = VehicleHealthLogic.getUserLevel(healthIndex);
    final medallas = VehicleHealthLogic.getQualityCertifications(
        pctCadena: pctCadena,
        pctFiltro: pctFiltro,
        pctAceite: pctAceite,
        pctSoat: pctSoat,
        pctTecno: pctTecno,
        routeCount: stats.routeCount,
        efficiencyScore: stats.aiAnalytics.careScore,
        totalSavings: stats.aiAnalytics.avgDailyKm * 0.1, // Cálculo simple o el que estimemos
        documentsComplete: documentsComplete,
        consistency: stats.aiAnalytics.consistency,
        hasLongRoute: stats.aiAnalytics.intensity == 'Alta');

    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(24),
      fallbackColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.02),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: brandTheme.primaryColor.withOpacity(0.1))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(text: 'Logros y Nivel'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Color(int.parse(level['color'])).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Color(int.parse(level['color'])))),
                  child: Row(children: [
                    Icon(Icons.workspace_premium,
                        size: 16, color: Color(int.parse(level['color']))),
                    const SizedBox(width: 6),
                    Text('Nivel ${level['name']}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(int.parse(level['color'])),
                            fontSize: 12))
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (medallas.isEmpty)
              const Text(
                  'Aún no tienes medallas. ¡Mantén tu vehículo al día para ganarlas!',
                  style: TextStyle(fontSize: 13, color: Colors.grey))
            else
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                      children: medallas.map((m) {
                    return Tooltip(
                      message: m['desc'],
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 2)),
                        child: Icon(m['icon'], color: Colors.amber, size: 24),
                      ),
                    );
                  }).toList())),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(text.toUpperCase(),
        style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 1.2,
            color: isDark ? Colors.white54 : Colors.black45));
  }
}
