// =============================================================================
// vehicle_ai_logic.dart — MOTOR IA DE DIAGNÓSTICO PREDICTIVO & TELEMETRÍA 2.0
// =============================================================================

import 'dart:math';
import 'vehicle_performance_logic.dart';

class WeeklyRouteBucket {
  final DateTime weekStart; // Lunes 00:00:00
  final DateTime weekEnd;   // Domingo 23:59:59
  final String label;       // ej: "24 Ago - 30 Ago 2026"
  final List<Map<String, dynamic>> routes;
  final double totalDistanceKm;
  final double totalGallons;
  final double totalCostCop;
  final double maxSpeedKmH;
  final double avgSpeedKmH;

  WeeklyRouteBucket({
    required this.weekStart,
    required this.weekEnd,
    required this.label,
    required this.routes,
    required this.totalDistanceKm,
    required this.totalGallons,
    required this.totalCostCop,
    required this.maxSpeedKmH,
    required this.avgSpeedKmH,
  });
}

class VehicleAILogic {
  /// Retorna el rango de la semana (Lunes 00:00 a Domingo 23:59) para una fecha dada
  static Map<String, DateTime> getWeekRange(DateTime date) {
    // En Dart: Monday = 1, Sunday = 7
    final monday = DateTime(date.year, date.month, date.day - (date.weekday - 1), 0, 0, 0);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
    return {'start': monday, 'end': sunday};
  }

  /// Agrupa la lista de rutas en bloques semanales de lunes a domingo.
  /// La semana en curso se reinicia a 0 cada domingo a medianoche (nuevo lunes).
  static List<WeeklyRouteBucket> groupRoutesByWeek(List<Map<String, dynamic>> routeHistory) {
    if (routeHistory.isEmpty) {
      final currentRange = getWeekRange(DateTime.now());
      return [
        WeeklyRouteBucket(
          weekStart: currentRange['start']!,
          weekEnd: currentRange['end']!,
          label: formatWeekLabel(currentRange['start']!, currentRange['end']!),
          routes: [],
          totalDistanceKm: 0.0,
          totalGallons: 0.0,
          totalCostCop: 0.0,
          maxSpeedKmH: 0.0,
          avgSpeedKmH: 0.0,
        )
      ];
    }

    final Map<String, List<Map<String, dynamic>>> buckets = {};
    final Map<String, Map<String, DateTime>> ranges = {};

    for (var r in routeHistory) {
      final fechaRaw = r['fecha'] ?? r['created_at'];
      DateTime dt = DateTime.now();
      if (fechaRaw is DateTime) {
        dt = fechaRaw;
      } else if (fechaRaw is String) {
        dt = DateTime.tryParse(fechaRaw)?.toLocal() ?? DateTime.now();
      }

      final range = getWeekRange(dt);
      final key = '${range['start']!.toIso8601String()}_${range['end']!.toIso8601String()}';
      
      buckets.putIfAbsent(key, () => []);
      buckets[key]!.add(r);
      ranges[key] = range;
    }

    // Asegurar que la semana actual esté siempre presente (incluso con 0 rutas si recién empezó el lunes)
    final nowRange = getWeekRange(DateTime.now());
    final nowKey = '${nowRange['start']!.toIso8601String()}_${nowRange['end']!.toIso8601String()}';
    if (!buckets.containsKey(nowKey)) {
      buckets[nowKey] = [];
      ranges[nowKey] = nowRange;
    }

    final List<WeeklyRouteBucket> result = [];

    buckets.forEach((key, routes) {
      final range = ranges[key]!;
      double dist = 0.0;
      double fuel = 0.0;
      double cost = 0.0;
      double vMax = 0.0;
      double vPromAcc = 0.0;
      int vPromCount = 0;

      for (var r in routes) {
        final dRaw = r['distancia_km'] ?? r['distancia'] ?? 0.0;
        final fRaw = r['consumo_galones'] ?? r['consumo_estimado'] ?? 0.0;
        final cRaw = r['costo_estimado'] ?? 0.0;
        final vmRaw = r['velocidad_max'] ?? 0.0;
        final vpRaw = r['velocidad_prom'] ?? 0.0;

        final d = (dRaw is num) ? dRaw.toDouble() : (double.tryParse(dRaw.toString()) ?? 0.0);
        final f = (fRaw is num) ? fRaw.toDouble() : (double.tryParse(fRaw.toString()) ?? 0.0);
        final c = (cRaw is num) ? cRaw.toDouble() : (double.tryParse(cRaw.toString()) ?? 0.0);
        final vm = (vmRaw is num) ? vmRaw.toDouble() : (double.tryParse(vmRaw.toString()) ?? 0.0);
        final vp = (vpRaw is num) ? vpRaw.toDouble() : (double.tryParse(vpRaw.toString()) ?? 0.0);

        dist += d;
        fuel += f;
        cost += c;
        if (vm > vMax) vMax = vm;
        if (vp > 0) {
          vPromAcc += vp;
          vPromCount++;
        }
      }

      final avgV = vPromCount > 0 ? (vPromAcc / vPromCount) : 0.0;

      result.add(WeeklyRouteBucket(
        weekStart: range['start']!,
        weekEnd: range['end']!,
        label: formatWeekLabel(range['start']!, range['end']!),
        routes: routes,
        totalDistanceKm: dist,
        totalGallons: fuel,
        totalCostCop: cost,
        maxSpeedKmH: vMax,
        avgSpeedKmH: avgV,
      ));
    });

    // Ordenar semanas de la más reciente a la más antigua
    result.sort((a, b) => b.weekStart.compareTo(a.weekStart));
    return result;
  }

  static String formatWeekLabel(DateTime start, DateTime end) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${end.year}';
  }

  /// Analiza patrones de conducción y genera "IA Insights" 100% en español con salud reactiva.
  static Map<String, dynamic> analyzeJourneyPatterns({
    required List<Map<String, dynamic>> routeHistory,
    required String modelName,
    bool isCar = false,
  }) {
    if (routeHistory.isEmpty) {
      return {
        'intensity': 'Baja',
        'consistency': 'Pendiente',
        'advice': 'Inicia tus recorridos para calibrar el análisis de salud y hábitos con IA.',
        'healthImpact': 0.0,
        'careScore': 100.0,
        'avgDailyKm': 0.0,
        'healthStatus': 'Excelente (En Espera)',
      };
    }

    double totalKm = 0;
    double maxObservedSpeed = 0;
    List<double> distances = [];

    for (var route in routeHistory) {
      final rawDist = route['distancia_km'] ?? route['distancia'] ?? 0.0;
      final rawSpeed = route['velocidad_max'] ?? 0.0;

      double d = (rawDist is num) ? rawDist.toDouble() : (double.tryParse(rawDist.toString()) ?? 0.0);
      double vm = (rawSpeed is num) ? rawSpeed.toDouble() : (double.tryParse(rawSpeed.toString()) ?? 0.0);

      totalKm += d;
      if (vm > maxObservedSpeed) maxObservedSpeed = vm;
      distances.add(d);
    }

    // Desviación estándar de distancias
    double avgDist = distances.isNotEmpty ? (totalKm / distances.length) : 0.0;
    double variance = distances.isNotEmpty
        ? distances.map((x) => pow(x - avgDist, 2)).reduce((a, b) => a + b) / distances.length
        : 0.0;
    double stdDev = sqrt(variance);

    // Factor de intensidad semanal (distancia total dividida en 7 días)
    double kmPerDay = totalKm / 7.0;
    String intensity = kmPerDay > 50 ? 'Alta' : (kmPerDay >= 15 ? 'Media' : 'Baja');
    String consistency = distances.length <= 1
        ? 'Pendiente'
        : (stdDev > (avgDist * 0.4) ? 'Variable' : 'Alta');

    // Cálculo dinámico del Care Score (Salud del Activo)
    double score = 100.0;

    // Penalización por alta exigencia o velocidad excesiva (> 100 km/h en moto o > 120 km/h en auto)
    final speedLimitRef = isCar ? 120.0 : 100.0;
    if (maxObservedSpeed > speedLimitRef) {
      final excess = maxObservedSpeed - speedLimitRef;
      score -= (excess * 0.4).clamp(0.0, 20.0);
    }

    if (intensity == 'Alta') score -= 15.0;
    if (consistency == 'Variable') score -= 5.0;

    score = score.clamp(40.0, 100.0);

    // Diagnóstico y consejos en español
    String advice = '';
    String healthStatus = 'Óptima';

    if (intensity == 'Alta') {
      advice = 'Uso intensivo detectado. Modera las aceleraciones y revisa periódicamente el nivel de aceite y la tensión de cadena.';
      healthStatus = 'Exigencia Alta';
    } else if (consistency == 'Variable') {
      advice = 'Patrón de viaje irregular con cambios bruscos de distancia. Mantén un monitoreo constante del vehículo.';
      healthStatus = 'Atención Recomendada';
    } else if (intensity == 'Baja') {
      advice = 'Conducción estable y bajo kilometraje. El motor y la transmisión operan en parámetros ideales.';
      healthStatus = 'Sobresaliente';
    } else {
      advice = 'Conducción equilibrada dentro de los parámetros de uso regular.';
      healthStatus = 'Buena';
    }

    double healthImpact = intensity == 'Alta' ? -2.5 : (score >= 90 ? 1.0 : 0.0);

    return {
      'intensity': intensity,
      'consistency': consistency,
      'advice': advice,
      'healthImpact': healthImpact,
      'avgDailyKm': kmPerDay,
      'careScore': score,
      'healthStatus': healthStatus,
    };
  }

  /// Predice posibles fallos o daños basados en el kilometraje total y el perfil de uso.
  static List<Map<String, dynamic>> predictUpcomingIssues({
    required int totalKms,
    required String intensity,
  }) {
    List<Map<String, dynamic>> issues = [];
    if (totalKms <= 0) return issues;
    
    double wearFactor = intensity == 'Alta' ? 1.6 : (intensity == 'Media' ? 1.0 : 0.85);

    int chainLife = (totalKms % 20000);
    if (chainLife > (17000 / wearFactor)) {
      issues.add({
        'item': 'Kit de Arrastre',
        'risk': 'Alto',
        'reason': 'Kilometraje próximo al límite de vida útil técnica recomendado.',
        'estimatedCostCop': 180000,
        'icon': 'settings_input_component',
        'color': '0xFFF44336',
      });
    }

    int brakeLife = (totalKms % 12000);
    if (brakeLife > (10500 / wearFactor)) {
      issues.add({
        'item': 'Pastillas de Freno',
        'risk': 'Medio',
        'reason': 'Desgaste por fricción acumulada en ciclo de kilometraje.',
        'estimatedCostCop': 85000,
        'icon': 'eject',
        'color': '0xFFFF9800',
      });
    }

    int sparkLife = (totalKms % 15000);
    if (sparkLife > (13500 / wearFactor)) {
      issues.add({
        'item': 'Bujías / Inyección',
        'risk': 'Medio',
        'reason': 'Se aproxima el ciclo de calibración o cambio preventivo.',
        'estimatedCostCop': 65000,
        'icon': 'bolt',
        'color': '0xFFFF9800',
      });
    }

    return issues;
  }

  /// Calcula el ahorro o sobrecosto inteligente de combustible comparado con el estándar del fabricante.
  static Map<String, dynamic> calculateSmartSavings({
    required double actualKm,
    required double actualFuelGallons,
    required String modelName,
    bool isCar = false,
    double localPrice = 15500.0,
  }) {
    if (actualKm <= 0 || actualFuelGallons <= 0) {
      return {
        'amount': 0.0,
        'gallonsSaved': 0.0,
        'isNegative': false,
        'label': 'Sin ahorro registrado',
      };
    }

    // MT 15 rinde aprox 135 km/gal
    final double efficiency = (modelName.toUpperCase().contains('MT 15') || modelName.toUpperCase().contains('MT15'))
        ? 135.0
        : (isCar ? 45.0 : 120.0);

    final double theoreticalGallons = actualKm / efficiency;
    final double gallonsSaved = theoreticalGallons - actualFuelGallons;
    final double amount = gallonsSaved * localPrice;

    String label;
    bool isNegative = false;

    if (gallonsSaved > 0.05) {
      label = '\$${amount.round()} COP ahorrado vs consumo promedio estimado.';
      isNegative = false;
    } else if (gallonsSaved < -0.5) {
      label = 'Consumo elevado: -\$${amount.abs().round()} COP sobre el promedio.';
      isNegative = true;
    } else if (gallonsSaved < 0) {
      label = 'Consumo promedio dentro de la banda neutral.';
      isNegative = true;
    } else {
      label = 'Consumo óptimo esperado.';
      isNegative = false;
    }

    return {
      'amount': amount,
      'gallonsSaved': gallonsSaved,
      'isNegative': isNegative,
      'label': label,
    };
  }
}

