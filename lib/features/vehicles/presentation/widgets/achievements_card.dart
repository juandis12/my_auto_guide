import 'package:flutter/material.dart';
import '../../../../core/logic/vehicle_health_logic.dart';
import '../../../../core/logic/performance_guard.dart';
import '../../../../core/theme/brand_theme.dart';
import '../../../../core/services/achievements_service.dart';
import '../../domain/models/weekly_stats.dart';

class AchievementsCard extends StatefulWidget {
  final String vehicleId;
  final WeeklyStats stats;
  final double pctCadena, pctFiltro, pctAceite, pctSoat, pctTecno;
  final BrandTheme brandTheme;
  final bool documentsComplete;
  final String modelName;

  const AchievementsCard({
    super.key,
    required this.vehicleId,
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
  State<AchievementsCard> createState() => _AchievementsCardState();
}

class _AchievementsCardState extends State<AchievementsCard> {
  List<Map<String, dynamic>> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  @override
  void didUpdateWidget(covariant AchievementsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pctAceite != widget.pctAceite ||
        oldWidget.stats.routeCount != widget.stats.routeCount ||
        oldWidget.documentsComplete != widget.documentsComplete) {
      _loadAchievements();
    }
  }

  Future<void> _loadAchievements() async {
    final list = await AchievementsService().syncAndGetAchievements(
      vehicleId: widget.vehicleId,
      pctCadena: widget.pctCadena,
      pctFiltro: widget.pctFiltro,
      pctAceite: widget.pctAceite,
      pctSoat: widget.pctSoat,
      pctTecno: widget.pctTecno,
      routeCount: widget.stats.routeCount,
      efficiencyScore: widget.stats.aiAnalytics.careScore,
      totalSavings: widget.stats.aiAnalytics.avgDailyKm * 0.1,
      documentsComplete: widget.documentsComplete,
      consistency: widget.stats.aiAnalytics.consistency,
      hasLongRoute: widget.stats.aiAnalytics.intensity == 'Alta',
    );

    if (mounted) {
      setState(() {
        _achievements = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthIndex = VehicleHealthLogic.calculateHealthIndex(
      pctCadena: widget.pctCadena,
      pctFiltro: widget.pctFiltro,
      pctAceite: widget.pctAceite,
      pctSoat: widget.pctSoat,
      pctTecno: widget.pctTecno,
    );
    final level = VehicleHealthLogic.getUserLevel(healthIndex);
    final int unlockedCount = _achievements.where((a) => a['isUnlocked'] == true).length;

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(24),
      sigma: isIOS ? 15.0 : 5.0,
      fallbackColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.02),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.02),
                  ]
                : [
                    Colors.black.withValues(alpha: 0.03),
                    Colors.black.withValues(alpha: 0.01),
                  ],
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(text: 'Logros y Medallas'),
                    const SizedBox(height: 2),
                    Text(
                      '$unlockedCount de ${_achievements.length} Desbloqueados',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(level['color']).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(level['color']), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspace_premium, size: 16, color: Color(level['color'])),
                      const SizedBox(width: 6),
                      Text(
                        'Nivel ${level['name']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(level['color']),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _achievements.map((m) {
                    final bool isUnlocked = m['isUnlocked'] == true;
                    final iconName = m['icon'] as String? ?? '';
                    final label = m['label'] as String? ?? 'Logro';
                    final desc = m['description'] as String? ?? '';
                    final req = m['requirement'] as String? ?? '';
                    final colorVal = m['color'] as int? ?? 0xFFFFD700;
                    final Color baseColor = isUnlocked ? Color(colorVal) : Colors.grey;

                    return Tooltip(
                      message: '$label: ${isUnlocked ? desc : req}',
                      child: GestureDetector(
                        onTap: () => _mostrarDetalleMedalla(context, m),
                        child: Container(
                          margin: const EdgeInsets.only(right: 14),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isUnlocked
                                          ? baseColor.withValues(alpha: 0.18)
                                          : (isDark ? Colors.white10 : Colors.black12),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isUnlocked
                                            ? baseColor
                                            : (isDark ? Colors.white24 : Colors.black26),
                                        width: isUnlocked ? 2.0 : 1.0,
                                      ),
                                      boxShadow: isUnlocked
                                          ? [
                                              BoxShadow(
                                                color: baseColor.withValues(alpha: 0.35),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      _getIconData(iconName),
                                      color: isUnlocked ? baseColor : (isDark ? Colors.white38 : Colors.black38),
                                      size: 24,
                                    ),
                                  ),
                                  if (!isUnlocked)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF20232B),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white70),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 68,
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                                    color: isUnlocked
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : (isDark ? Colors.white38 : Colors.black38),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalleMedalla(BuildContext context, Map<String, dynamic> m) {
    final bool isUnlocked = m['isUnlocked'] == true;
    final iconName = m['icon'] as String? ?? '';
    final label = m['label'] as String? ?? 'Logro';
    final desc = m['description'] as String? ?? '';
    final req = m['requirement'] as String? ?? '';
    final colorVal = m['color'] as int? ?? 0xFFFFD700;
    final Color baseColor = isUnlocked ? Color(colorVal) : Colors.grey;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIconData(iconName), color: baseColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  Text(
                    isUnlocked ? '✨ ¡Medalla Desbloqueada!' : '🔒 Bloqueado',
                    style: TextStyle(
                      color: isUnlocked ? const Color(0xFF30D158) : Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              desc,
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(
                    isUnlocked ? Icons.check_circle_rounded : Icons.flag_rounded,
                    size: 16,
                    color: isUnlocked ? const Color(0xFF30D158) : Colors.blueAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isUnlocked ? 'Permanente en tu Garaje.' : 'Cómo obtenerla: $req',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
        ],
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
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 1.2,
        color: isDark ? Colors.white54 : Colors.black45,
      ),
    );
  }
}
