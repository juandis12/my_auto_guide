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

    return certs;
  }

  /// Calcula la fecha estimada de próximo mantenimiento basado en el uso real.
  /// Se calcula un "Factor de Desgaste" comparando el uso real vs uso base.
  static Map<String, dynamic> predictMaintenance({
    required String item,
    required DateTime? lastDate,
    required int baseDays,
    required List<Map<String, dynamic>> routeHistory,
  }) {
    if (lastDate == null || routeHistory.isEmpty) {
      return {'status': 'Sin datos suficientes'};
    }

    // 1. Calcular km recorridos en los últimos 7 días
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    double totalKmLast7Days = 0;
    for (var route in routeHistory) {
      final fechaRaw = route['fecha'] ?? route['created_at'];
      if (fechaRaw == null) continue;
      
      final date = fechaRaw is DateTime 
          ? fechaRaw 
          : DateTime.tryParse(fechaRaw.toString());
          
      if (date != null && date.isAfter(sevenDaysAgo)) {
        // Usar distancia_km (nuevo nombre) o distancia (antiguo)
        final dist = (route['distancia_km'] ?? route['distancia'] ?? 0) as num;
        totalKmLast7Days += dist.toDouble();
      }
    }

    double kmPerDay = totalKmLast7Days / 7;
    
    // 2. Definir Uso Base Standard (ej. 25km/día es un uso normal)
    const double standardDailyUsage = 25.0;
    
    // 3. Calcular Factor de Desgaste (Mínimo 0.5x, máximo 4x)
    double wearFactor = (kmPerDay / standardDailyUsage).clamp(0.5, 4.0);
    
    // 4. Calcular días restantes teóricos vs reales
    int elapsedDays = now.difference(lastDate).inDays;
    double adjustedTotalDays = baseDays / wearFactor;
    int remainingDays = (adjustedTotalDays - elapsedDays).round();

    final estimatedDate = now.add(Duration(days: remainingDays > 0 ? remainingDays : 0));

    return {
      'status': remainingDays <= 0 ? 'Vencido' : 'Proyectado',
      'days': remainingDays,
      'date': estimatedDate,
      'wearFactor': wearFactor,
      'kmPerDay': kmPerDay,
      'item': item,
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
