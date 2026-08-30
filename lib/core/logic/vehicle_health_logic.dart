import 'dart:math';

class VehicleHealthLogic {
  /// Calcula el Índice de Salud del Vehículo (ISH) de 0 a 100%.
  /// Se basa en el promedio ponderado de los mantenimientos y documentos.
  static double calculateHealthIndex({
    required double pctCadena,
    required double pctFiltro,
    required double pctAceite,
    required double pctSoat,
    required double pctTecno,
  }) {
    // Los documentos (SOAT/Tecno) tienen un peso crítico para la "Salud Legal"
    // Los mantenimientos mecánicos para la "Salud Mecánica"
    double mechanicHealth = (pctCadena + pctFiltro + pctAceite) / 3;
    double legalHealth = (pctSoat + pctTecno) / 2;

    // El índice global pondera ambos (60% mecánica, 40% legal)
    return (mechanicHealth * 0.6 + legalHealth * 0.4) * 100;
  }

  /// Calcula el porcentaje de vida útil restante comparando Tiempo vs Kilometraje.
  /// Retorna el factor más crítico (el menor de ambos).
  /// Si el kilometraje se agota en 4 días (ej: 3,000 km recorridos rápidamente),
  /// el porcentaje cae a 0% independientemente del tiempo restante.
  static double calculateHybridPercentage({
    required DateTime? lastDate,
    required double lastKms,
    required int cycleDays,
    required int cycleKms,
    required double currentKms,
  }) {
    if (lastDate == null) return 0.0;

    // 1. Desgaste por Tiempo
    final elapsedDays = DateTime.now().difference(lastDate).inDays;
    final timeRemainingPct = 1.0 - (elapsedDays / cycleDays);

    // 2. Desgaste por Kilometraje
    double kmsRemainingPct = 1.0;
    if (lastKms > 0) {
      final elapsedKms = (currentKms - lastKms).clamp(0.0, double.infinity);
      kmsRemainingPct = 1.0 - (elapsedKms / cycleKms);
    }

    // 3. El factor dominante es el menor estricto
    return [timeRemainingPct, kmsRemainingPct]
        .reduce((a, b) => a < b ? a : b)
        .clamp(0.0, 1.0);
  }

  /// Calcula los días restantes para mantenimiento según la regla automotriz del menor:
  /// Días = min(Días restantes por calendario, Días restantes por kilometraje según promedio diario)
  static int calculateProjectedRemainingDays({
    required DateTime? lastDate,
    required double lastKms,
    required int cycleDays,
    required int cycleKms,
    required double currentKms,
    required double avgKmPerDay,
  }) {
    if (lastDate == null) return 0;

    final elapsedDays = DateTime.now().difference(lastDate).inDays;
    final int calendarDaysRemaining = cycleDays - elapsedDays;

    if (lastKms <= 0 || avgKmPerDay <= 0) {
      return calendarDaysRemaining;
    }

    final double elapsedKms = (currentKms - lastKms).clamp(0.0, double.infinity);
    final double remainingKms = (cycleKms - elapsedKms);

    if (remainingKms <= 0) {
      return 0; // Ya vencido por kilometraje
    }

    final int kmDaysRemaining = (remainingKms / avgKmPerDay).round();

    // Regla del menor: lo que ocurra primero
    return min(calendarDaysRemaining, kmDaysRemaining);
  }

  /// Retorna la categoría profesional del estado del vehículo.
  static String getVehicleStatus(double healthIndex) {
    if (healthIndex >= 90) return 'Estado de Exhibición';
    if (healthIndex >= 75) return 'Mantenimiento Sobresaliente';
    if (healthIndex >= 60) return 'Operación Óptima';
    if (healthIndex >= 45) return 'Revisión Preventiva Sugerida';
    return 'Atención Inmediata Requerida';
  }

  /// Retorna el Nivel de Usuario basado en el Score.
  static Map<String, dynamic> getUserLevel(double healthIndex) {
    if (healthIndex >= 90) return {'name': 'Diamante', 'color': 0xFF00E5FF};
    if (healthIndex >= 75) return {'name': 'Oro', 'color': 0xFFFFD700};
    if (healthIndex >= 50) return {'name': 'Plata', 'color': 0xFFC0C0C0};
    return {'name': 'Bronce', 'color': 0xFFCD7F32};
  }

  /// Retorna una descripción técnica del estado enfocada en el reporte semanal.
  static String getWeeklySummary(double healthIndex) {
    if (healthIndex >= 75) {
      return 'Resumen Semanal: El activo mantiene sus certificaciones de calidad y operación al día.';
    }
    if (healthIndex >= 55) {
      return 'Resumen Semanal: Operación estable. Indicadores preventivos dentro del margen de servicio.';
    }
    return 'Alerta Semanal: Se detectan servicios próximos a vencer. Agenda tu mantenimiento preventivo.';
  }

  /// Retorna los "Sellos de Calidad" (hitos logrados).
  static List<Map<String, dynamic>> getQualityCertifications({
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
  }) {
    List<Map<String, dynamic>> certs = [];

    if (pctAceite > 0.9) {
      certs.add({
        'id': 'oil_certified',
        'label': 'Sello de Lubricación',
        'description': 'Aceite en estado óptimo.',
        'icon': 'verified',
        'color': '0xFF4CAF50',
      });
    }

    if (pctSoat > 0.9 && pctTecno > 0.9) {
      certs.add({
        'id': 'legal_certified',
        'label': 'Legitimidad Total',
        'description': 'Todo al día con la ley.',
        'icon': 'gavel',
        'color': '0xFF2196F3',
      });
    }

    if (pctFiltro > 0.8 && pctCadena > 0.8) {
      certs.add({
        'id': 'performance_certified',
        'label': 'Corazón de Hierro',
        'description': 'Transmisión y admisión OK.',
        'icon': 'settings_input_component',
        'color': '0xFFFF9800',
      });
    }

    if (routeCount >= 10) {
      certs.add({
        'id': 'travel_pro',
        'label': 'Viajero Experto',
        'description': 'Más de 10 rutas registradas.',
        'icon': 'map',
        'color': '0xFF9C27B0',
      });
    }

    if (efficiencyScore >= 90) {
      certs.add({
        'id': 'eco_driver',
        'label': 'Pie de Pluma',
        'description': 'Eficiencia de combustible > 90%.',
        'icon': 'eco',
        'color': '0xFF4CAF50',
      });
    }

    if (totalSavings >= 50000) {
      certs.add({
        'id': 'smart_saver',
        'label': 'Lobo de Wall Street',
        'description': 'Ahorro mayor a \$50K COP.',
        'icon': 'savings',
        'color': '0xFFFF4081',
      });
    }

    if (documentsComplete) {
      certs.add({
        'id': 'paperless',
        'label': 'Nube Maestra',
        'description': 'Todos los documentos digitales.',
        'icon': 'cloud_done',
        'color': '0xFF03A9F4',
      });
    }

    if (consistency == 'Alta') {
      certs.add({
        'id': 'visionary_mechanic',
        'label': 'Mecánico Visionario',
        'description': 'Manejo constante sin sobresaltos.',
        'icon': 'shield',
        'color': '0xFF607D8B',
      });
    }

    if (hasLongRoute) {
      certs.add({
        'id': 'marathoner',
        'label': 'Trotamundos',
        'description': 'Viaje continuo de +100 km.',
        'icon': 'terrain',
        'color': '0xFF795548',
      });
    }

    return certs;
  }

  /// Calcula la fecha estimada de próximo mantenimiento basado en el uso real (Km/Día vs Calendario).
  static Map<String, dynamic> predictMaintenance({
    required String item,
    required DateTime? lastDate,
    double lastKms = 0.0,
    double currentKms = 0.0,
    int cycleKms = 3000,
    int cycleDays = 90,
    double avgKmPerDay = 25.0,
    int? baseDays,
    List<Map<String, dynamic>>? routeHistory,
  }) {
    if (lastDate == null) {
      return {'status': 'Sin datos suficientes'};
    }

    double finalAvgKmPerDay = avgKmPerDay;
    if (routeHistory != null && routeHistory.isNotEmpty) {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      double totalKmLast7Days = 0;
      for (var route in routeHistory) {
        final fechaRaw = route['fecha'] ?? route['created_at'];
        if (fechaRaw == null) continue;
        final date = fechaRaw is DateTime ? fechaRaw : DateTime.tryParse(fechaRaw.toString());
        if (date != null && date.isAfter(sevenDaysAgo)) {
          final rawDist = route['distancia_km'] ?? route['distancia'] ?? 0;
          final dist = rawDist is num ? rawDist.toDouble() : (double.tryParse(rawDist.toString()) ?? 0.0);
          totalKmLast7Days += dist;
        }
      }
      if (totalKmLast7Days > 0) {
        finalAvgKmPerDay = totalKmLast7Days / 7;
      }
    }

    final int remainingDays = calculateProjectedRemainingDays(
      lastDate: lastDate,
      lastKms: lastKms,
      cycleDays: cycleDays,
      cycleKms: cycleKms,
      currentKms: currentKms,
      avgKmPerDay: finalAvgKmPerDay,
    );

    final estimatedDate = DateTime.now().add(Duration(days: remainingDays > 0 ? remainingDays : 0));
    final bool isKmDominant = (lastKms > 0 && finalAvgKmPerDay > 0) &&
        ((cycleKms - (currentKms - lastKms)) / finalAvgKmPerDay).round() < (cycleDays - DateTime.now().difference(lastDate).inDays);

    return {
      'status': remainingDays <= 0 ? 'Vencido' : 'Proyectado',
      'days': remainingDays,
      'date': estimatedDate,
      'kmPerDay': finalAvgKmPerDay,
      'item': item,
      'isKmDominant': isKmDominant,
      'reason': remainingDays <= 0
          ? 'Mantenimiento vencido'
          : (isKmDominant ? 'Proyectado por ritmo de kilometraje' : 'Proyectado por tiempo'),
      'risk': remainingDays <= 0 ? 'Alto' : (remainingDays <= 14 ? 'Medio' : 'Bajo'),
      'isCritical': remainingDays <= 3,
    };
  }

  /// Genera consejos proactivos basados en proyecciones.
  static List<String> getProactiveAdvice({
    required List<Map<String, dynamic>> predictions,
  }) {
    List<String> advice = [];

    for (var pred in predictions) {
      final days = pred['days'] as int?;
      final item = pred['item'] as String;
      final bool isKm = pred['isKmDominant'] as bool? ?? false;

      if (days != null) {
        if (days <= 0) {
          advice.add('🚨 CRÍTICO: El servicio de $item ya está vencido.');
        } else if (days <= 7) {
          advice.add(isKm
              ? '⚠️ ALERTA: Por tu ritmo de kilometraje, tu $item requiere atención en aprox. $days días.'
              : '⚠️ ALERTA: Tu $item requiere atención en aprox. $days días.');
        } else if (days <= 21) {
          advice.add('📅 AVISO: Programa el servicio de $item para las próximas 2-3 semanas.');
        }
      }
    }
    return advice;
  }
}
