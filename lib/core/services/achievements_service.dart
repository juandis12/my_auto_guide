import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementItem {
  final String id;
  final String label;
  final String description;
  final String icon;
  final int color;
  final String unlockRequirement;

  const AchievementItem({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlockRequirement,
  });
}

const List<AchievementItem> kAllAchievements = [
  AchievementItem(
    id: 'oil_certified',
    label: 'Sello de Lubricación',
    description: 'Aceite de motor en estado óptimo (>90% de vida útil).',
    icon: 'verified',
    color: 0xFF4CAF50,
    unlockRequirement: 'Mantén el aceite por encima del 90%',
  ),
  AchievementItem(
    id: 'legal_certified',
    label: 'Legitimidad Total',
    description: 'Documentación al día: SOAT y Tecnomecánica vigentes.',
    icon: 'gavel',
    color: 0xFF2196F3,
    unlockRequirement: 'Ten SOAT y Tecnomecánica activos',
  ),
  AchievementItem(
    id: 'performance_certified',
    label: 'Corazón de Hierro',
    description: 'Excelente estado de transmisión y admisión (>80%).',
    icon: 'settings_input_component',
    color: 0xFFFF9800,
    unlockRequirement: 'Mantén cadena/correa y filtro sobre el 80%',
  ),
  AchievementItem(
    id: 'travel_pro',
    label: 'Viajero Experto',
    description: 'Más de 10 rutas registradas y completadas con GPS.',
    icon: 'map',
    color: 0xFF9C27B0,
    unlockRequirement: 'Registra y completa al menos 10 rutas',
  ),
  AchievementItem(
    id: 'eco_driver',
    label: 'Pie de Pluma',
    description: 'Conducción eficiente con índice de cuidado > 90%.',
    icon: 'eco',
    color: 0xFF00E676,
    unlockRequirement: 'Alcanza una eficiencia de combustible > 90%',
  ),
  AchievementItem(
    id: 'smart_saver',
    label: 'Lobo de Wall Street',
    description: 'Ahorro proyectado superior a \$50,000 COP en combustible.',
    icon: 'savings',
    color: 0xFFFF4081,
    unlockRequirement: 'Ahorra más de \$50K COP con rutas inteligentes',
  ),
  AchievementItem(
    id: 'paperless',
    label: 'Nube Maestra',
    description: 'Todos los documentos del vehículo digitalizados.',
    icon: 'cloud_done',
    color: 0xFF03A9F4,
    unlockRequirement: 'Sube todos los documentos al Garaje',
  ),
  AchievementItem(
    id: 'visionary_mechanic',
    label: 'Mecánico Visionario',
    description: 'Manejo constante y mantenimiento preventivo al día.',
    icon: 'shield',
    color: 0xFF607D8B,
    unlockRequirement: 'Consistencia alta en tus mantenimientos',
  ),
  AchievementItem(
    id: 'marathoner',
    label: 'Trotamundos',
    description: 'Completaste un recorrido continuo de más de 100 km.',
    icon: 'terrain',
    color: 0xFFFF6D00,
    unlockRequirement: 'Realiza un viaje de más de 100 km',
  ),
];

class AchievementsService {
  static final AchievementsService _instance = AchievementsService._internal();
  factory AchievementsService() => _instance;
  AchievementsService._internal();

  /// Evalúa y guarda permanentemente los logros que se hayan cumplido
  Future<List<Map<String, dynamic>>> syncAndGetAchievements({
    required String vehicleId,
    required double pctCadena,
    required double pctFiltro,
    required double pctAceite,
    required double pctSoat,
    required double pctTecno,
    int routeCount = 0,
    double efficiencyScore = 0.0,
    double totalSavings = 0.0,
    bool documentsComplete = false,
    String consistency = 'Variable',
    bool hasLongRoute = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'unlocked_achievements_$vehicleId';
      final savedRaw = prefs.getString(key);

      Map<String, dynamic> unlockedMap = {};
      if (savedRaw != null) {
        try {
          unlockedMap = jsonDecode(savedRaw) as Map<String, dynamic>;
        } catch (_) {}
      }

      final nowIso = DateTime.now().toIso8601String();

      // Reglas de desbloqueo (una vez desbloqueado, NUNCA se pierde)
      if (pctAceite >= 0.90) {
        unlockedMap.putIfAbsent('oil_certified', () => nowIso);
      }
      if (pctSoat >= 0.90 && pctTecno >= 0.90) {
        unlockedMap.putIfAbsent('legal_certified', () => nowIso);
      }
      if (pctFiltro >= 0.80 && pctCadena >= 0.80) {
        unlockedMap.putIfAbsent('performance_certified', () => nowIso);
      }
      if (routeCount >= 10) {
        unlockedMap.putIfAbsent('travel_pro', () => nowIso);
      }
      if (efficiencyScore >= 90) {
        unlockedMap.putIfAbsent('eco_driver', () => nowIso);
      }
      if (totalSavings >= 50000) {
        unlockedMap.putIfAbsent('smart_saver', () => nowIso);
      }
      if (documentsComplete) {
        unlockedMap.putIfAbsent('paperless', () => nowIso);
      }
      if (consistency == 'Alta') {
        unlockedMap.putIfAbsent('visionary_mechanic', () => nowIso);
      }
      if (hasLongRoute) {
        unlockedMap.putIfAbsent('marathoner', () => nowIso);
      }

      // Guardar mapa persistente
      await prefs.setString(key, jsonEncode(unlockedMap));

      // Retornar lista completa con estados desbloqueado / bloqueado
      return kAllAchievements.map((item) {
        final bool isUnlocked = unlockedMap.containsKey(item.id);
        final String? unlockedAt = unlockedMap[item.id]?.toString();
        return {
          'id': item.id,
          'label': item.label,
          'description': item.description,
          'icon': item.icon,
          'color': item.color,
          'requirement': item.unlockRequirement,
          'isUnlocked': isUnlocked,
          'unlockedAt': unlockedAt,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error en syncAndGetAchievements: $e');
      return [];
    }
  }
}
