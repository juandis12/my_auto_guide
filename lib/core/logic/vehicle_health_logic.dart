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
    if (healthIndex >= 50) return 'Mantenimiento Requerido';
    return 'Atención Inmediata';
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
    if (healthIndex >= 70) {
      return 'Resumen Semanal: El activo mantiene sus certificaciones de calidad y operación al día.';
    }
    return 'Alerta Semanal: Se detectan servicios próximos a vencer o atención requerida.';
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
        'label': 'Sello Legal',
        'description': 'Documentos al día.',
        'icon': 'description',
        'color': '0xFF2196F3',
      });
    }

    if (pctCadena > 0.9 && pctFiltro > 0.9) {
      certs.add({
        'id': 'performance_certified',
        'label': 'Sello Mecánico',
        'description': 'Componentes clave en excelente estado.',
        'icon': 'build_circle',
        'color': '0xFF9C27B0',
      });
    }

    if (routeCount >= 5) {
      certs.add({
        'id': 'travel_pro',
        'label': 'Viajero Frecuente',
        'description': 'Más de 5 trayectos registrados.',
        'icon': 'explore',
        'color': '0xFFFF9800',
      });
    }

    if (efficiencyScore >= 80) {
      certs.add({
        'id': 'eco_driver',
        'label': 'Conductor Eficiente',
        'description': 'Consumo óptimo de combustible.',
        'icon': 'eco',
        'color': '0xFF4CAF50',
      });
    }

    if (totalSavings > 10000) {
      certs.add({
        'id': 'smart_saver',
        'label': 'Ahorrador Inteligente',
        'description': 'Ahorro significativo en combustible.',
        'icon': 'savings',
        'color': '0xFFFFD700',
      });
    }

    if (documentsComplete) {
      certs.add({
        'id': 'paperless',
        'label': 'Guantera Digital',
        'description': 'Documentación digital completa.',
        'icon': 'folder_special',
        'color': '0xFF00BCD4',
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
    int cycleDays = 30,
    double? avgKmPerDay,
    int? baseDays,
    List<Map<String, dynamic>>? routeHistory,
  }) {
    if (lastDate == null) {
      return {'status': 'Sin datos suficientes'};
    }

    double? computedAvgKm;
    if (routeHistory != null) {
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
      computedAvgKm = totalKmLast7Days / 7.0;
    } else if (avgKmPerDay != null) {
      computedAvgKm = avgKmPerDay;
    }

    if (computedAvgKm == null) {
      return {
        'status': 'Sin uso reciente',
        'item': item,
      };
    }

    const double standardDailyKm = 25.0;
    final double wearFactor = (computedAvgKm / standardDailyKm).clamp(0.5, 4.0);

    final int effectiveCycleDays = (cycleDays / wearFactor).round();
    final int daysElapsed = DateTime.now().difference(lastDate).inDays;
    final int remainingDays = effectiveCycleDays - daysElapsed;

    final isOverdue = remainingDays <= 0;
    final estimatedDate = DateTime.now().add(Duration(days: isOverdue ? 0 : remainingDays));

    return {
      'status': isOverdue ? 'Vencido' : 'Proyectado',
      'days': remainingDays,
      'date': estimatedDate,
      'kmPerDay': computedAvgKm,
      'wearFactor': wearFactor,
      'item': item,
      'reason': isOverdue ? 'Uso intensivo detectado' : 'Proyectado por ritmo de uso',
      'risk': isOverdue ? 'Alto' : (remainingDays <= 14 ? 'Medio' : 'Bajo'),
      'isCritical': isOverdue || remainingDays <= 3,
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
