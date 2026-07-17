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

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(24),
      sigma: isIOS ? 15.0 : 5.0,
      fallbackColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.02),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: isIOS
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.02),
                        ]
                      : [
                          Colors.black.withOpacity(0.03),
                          Colors.black.withOpacity(0.01),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.08),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: brandTheme.primaryColor.withOpacity(0.1))),
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
                      color: Color(level['color']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Color(level['color']))),
                  child: Row(children: [
                    Icon(Icons.workspace_premium,
                        size: 16, color: Color(level['color'])),
                    const SizedBox(width: 6),
                    Text('Nivel ${level['name']}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(level['color']),
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
                    final iconName = m['icon'] as String? ?? '';
                    final desc = m['description'] as String? ?? m['desc'] as String? ?? '';
                    return Tooltip(
                      message: desc,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(_getIconData(iconName), color: Colors.amber, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      m['label'] as String? ?? 'Logro de Conducción',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                              content: Text(
                                desc,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('¡Excelente!', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber, width: 2)),
                          child: Icon(_getIconData(iconName), color: Colors.amber, size: 24),
                        ),
                      ),
                    );
                  }).toList())),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'verified':
        return Icons.verified_rounded;
      case 'gavel':
        return Icons.gavel_rounded;
      case 'settings_input_component':
        return Icons.settings_input_component_rounded;
      case 'map':
        return Icons.map_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'cloud_done':
        return Icons.cloud_done_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'terrain':
        return Icons.terrain_rounded;
      default:
        return Icons.stars_rounded;
    }
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
