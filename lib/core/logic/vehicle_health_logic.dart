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
    
     // El índice global pondera ambos (60% mecánica, 40% legal por ejemplo)
    return (mechanicHealth * 0.6 + legalHealth * 0.4) * 100;
  }

  /// Calcula el porcentaje de vida útil restante comparando Tiempo vs Kilometraje.
  /// Retorna el factor más crítico (el menor de ambos).
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
    // Si lastKms es 0 o null (dato no ingresado aún), ignoramos este factor
    double kmsRemainingPct = 1.0;
    if (lastKms > 0) {
      final elapsedKms = (currentKms - lastKms).clamp(0.0, double.infinity);
      kmsRemainingPct = 1.0 - (elapsedKms / cycleKms);
    }

    // 3. El factor dominante es el menor (el que más se haya desgastado)
    return [timeRemainingPct, kmsRemainingPct]
        .reduce((a, b) => a < b ? a : b)
        .clamp(0.0, 1.0);
  }

  /// Retorna la categoría profesional del estado del vehículo.
  static String getVehicleStatus(double healthIndex) {
    if (healthIndex >= 95) return 'Estado de Exhibición';
    if (healthIndex >= 85) return 'Mantenimiento Sobresaliente';
    if (healthIndex >= 70) return 'Operación Óptima';
    if (healthIndex >= 50) return 'Mantenimiento Requerido';
    return 'Atención Inmediata';
  }

  /// Retorna el Nivel de Usuario basado en el Score.
  static Map<String, dynamic> getUserLevel(double healthIndex) {
    if (healthIndex >= 90) return {'name': 'Diamante', 'color': '0xFF00E5FF'};
    if (healthIndex >= 75) return {'name': 'Oro', 'color': '0xFFFFD700'};
    if (healthIndex >= 50) return {'name': 'Plata', 'color': '0xFFC0C0C0'};
    return {'name': 'Bronce', 'color': '0xFFCD7F32'};
  }

  /// Retorna una descripción técnica del estado enfocada en el reporte semanal.
  static String getWeeklySummary(double healthIndex) {
    if (healthIndex >= 85) {
      return 'Resumen Semanal: El activo mantiene sus certificaciones de calidad. Valorización estable.';
    }
    if (healthIndex >= 70) {
      return 'Resumen Semanal: Mantenimientos dentro de rango. Se recomienda revisión de indicadores preventivos.';
    }
    return 'Alerta Semanal: Se han detectado desviaciones en el cronograma de mantenimiento que afectan la salud del activo.';
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

  /// Calcula la fecha estimada de próximo mantenimiento basado en el uso real.
  /// Se calcula un "Factor de Desgaste" comparando el uso real vs uso base.
  static Map<String, dynamic> predictMaintenance({
    required String item,
    required DateTime? lastDate,
    int? baseDays, // Antiguo parámetro
    List<Map<String, dynamic>>? routeHistory, // Antiguo parámetro
    double? avgKmPerDay, // Nuevo: Promedio pre-calculado
    int? cycleDays, // Nuevo: Días de ciclo alternativo
  }) {
    if (lastDate == null) {
      return {'status': 'Sin datos suficientes'};
    }

    double finalAvgKmPerDay = 0;
    
    if (avgKmPerDay != null) {
      finalAvgKmPerDay = avgKmPerDay;
    } else if (routeHistory != null && routeHistory.isNotEmpty) {
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
      finalAvgKmPerDay = totalKmLast7Days / 7;
    }

    if (finalAvgKmPerDay == 0 && (routeHistory == null || routeHistory.isEmpty)) {
      return {'status': 'Sin uso reciente', 'item': item};
    }

    // 2. Definir Uso Base Standard (ej. 25km/día es un uso normal)
    const double standardDailyUsage = 25.0;
    
    // 3. Calcular Factor de Desgaste (Mínimo 0.5x, máximo 4x)
    double wearFactor = (finalAvgKmPerDay / standardDailyUsage).clamp(0.5, 4.0);
    
    // 4. Calcular días restantes teóricos vs reales
    int elapsedDays = DateTime.now().difference(lastDate).inDays;
    int effectiveBaseDays = cycleDays ?? baseDays ?? 30; // Fallback a 30 días si no hay nada
    double adjustedTotalDays = effectiveBaseDays / wearFactor;
    int remainingDays = (adjustedTotalDays - elapsedDays).round();

    final estimatedDate = DateTime.now().add(Duration(days: remainingDays > 0 ? remainingDays : 0));

    return {
      'status': remainingDays <= 0 ? 'Vencido' : 'Proyectado',
      'days': remainingDays,
      'date': estimatedDate,
      'wearFactor': wearFactor,
      'kmPerDay': finalAvgKmPerDay,
      'item': item,
      'reason': remainingDays <= 7 ? 'Uso intensivo detectado' : 'Mantenimiento preventivo',
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
      
      if (days != null) {
        if (days <= 7) {
          advice.add('⚠️ ALERTA: Tu $item requiere atención en aprox. $days días.');
        } else if (days <= 21) {
          advice.add('📅 AVISO: Programa el servicio de $item para las próximas 2-3 semanas.');
        }
      }
    }
    return advice;
  }
}
