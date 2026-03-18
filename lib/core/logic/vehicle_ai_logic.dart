import 'dart:math';
import 'vehicle_performance_logic.dart';

class VehicleAILogic {
  /// Analiza patrones de conducción y genera "AI Insights".
  /// Simula el procesamiento de telemetría para detectar irregularidades.
  static Map<String, dynamic> analyzeJourneyPatterns({
    required List<Map<String, dynamic>> routeHistory,
    required String modelName,
    bool isCar = false,
  }) {
    if (routeHistory.isEmpty) {
      return {
        'intensity': 'Baja',
        'consistency': 'Pendiente',
        'advice': 'Realiza más trayectos para activar el análisis de IA.',
        'healthImpact': 0.0,
        'careScore': 100.0,
        'avgDailyKm': 0.0,
      };
    }

    double totalKm = 0;
    List<double> distances = [];

    for (var route in routeHistory) {
      final rawDist = route['distancia_km'] ?? route['distancia'] ?? 0.0;
      double d = 0.0;
      if (rawDist is num) {
        d = rawDist.toDouble();
      } else {
        d = double.tryParse(rawDist.toString()) ?? 0.0;
      }
      
      totalKm += d;
      distances.add(d);
    }

    // Análisis de consistencia (Desviación estándar de distancias)
    double avgDist = totalKm / routeHistory.length;
    double variance = distances.map((x) => pow(x - avgDist, 2)).reduce((a, b) => a + b) / distances.length;
    double stdDev = sqrt(variance);

    // Factor de intensidad (Basado en km/día promedio)
    double kmPerDay = totalKm / 7; // Asumiendo última semana
    String intensity = kmPerDay > 50 ? 'Alta' : (kmPerDay > 15 ? 'Media' : 'Baja');

    // AI Advice dinámico
    String advice = '';
    if (stdDev > avgDist * 0.5) {
      advice = 'Patrón de uso irregular detectado. Revisa la presión de llantas antes de viajes largos.';
    } else if (intensity == 'Alta') {
      advice = 'Uso intensivo detectado. Considera adelantar el cambio de aceite un 10%.';
    } else {
      advice = 'Conducción estable. El desgaste se mantiene dentro de los parámetros ideales.';
    }

    return {
      'intensity': intensity,
      'consistency': stdDev < (avgDist * 0.3) ? 'Alta' : 'Variable',
      'advice': advice,
      'healthImpact': intensity == 'Alta' ? -2.5 : 1.0,
      'avgDailyKm': kmPerDay,
      'careScore': _calculateCareScore(intensity, stdDev, avgDist),
    };
  }

  static double _calculateCareScore(String intensity, double stdDev, double avgDist) {
    double score = 100.0;
    if (intensity == 'Alta') score -= 15;
    if (stdDev > avgDist * 0.5) score -= 10;
    return score.clamp(0.0, 100.0);
  }

  /// Calcula el ahorro real potenciado por IA (considerando variabilidad de precios).
  static Map<String, dynamic> calculateSmartSavings({
    required double actualKm,
    required double actualFuelGallons,
    required String modelName,
    bool isCar = false,
    double localPrice = 15500,
  }) {
    if (actualKm <= 0 || actualFuelGallons <= 0) {
      return {'amount': 0.0, 'label': 'Sin ahorro registrado', 'isNegative': false};
    }

    final idealYield = VehiclePerformanceLogic.getKmPerGalon(modelName, isCar: isCar);
    final idealFuel = actualKm / idealYield;
    
    final savingsGallons = idealFuel - actualFuelGallons;
    final savingsMoney = savingsGallons * localPrice;

    String label = '';
    if (savingsMoney > 5000) {
      label = '¡Excelente gestión! Has ahorrado combustible.';
    } else if (savingsMoney < -5000) {
      label = 'Consumo elevado. Revisa tu estilo de conducción.';
    } else {
      label = 'Consumo dentro del promedio esperado.';
    }

    return {
      'amount': savingsMoney,
      'label': label,
      'isNegative': savingsMoney < 0,
      'gallonsSaved': savingsGallons,
    };
  }

  /// Predice posibles fallos o daños basados en el kilometraje total y el perfil de uso.
  static List<Map<String, dynamic>> predictUpcomingIssues({
    required int totalKms,
    required String intensity,
  }) {
    List<Map<String, dynamic>> issues = [];
    
    // Multiplicador de desgaste basado en intensidad
    double wearFactor = intensity == 'Alta' ? 1.4 : (intensity == 'Media' ? 1.0 : 0.8);

    // 1. Kit de Arrastre / Cadena (Periodo crítico cada 20,000km)
    int chainLife = (totalKms % 20000);
    if (chainLife > 17000 * (1/wearFactor)) {
      issues.add({
        'item': 'Kit de Arrastre',
        'risk': 'Alto',
        'reason': 'Kilometraje próximo al límite de vida útil técnica.',
        'icon': 'settings_input_component',
        'color': '0xFFF44336',
      });
    }

    // 2. Pastillas de Freno (Periodo medio cada 12,000km)
    int brakeLife = (totalKms % 12000);
    if (brakeLife > 10000 * (1/wearFactor)) {
      issues.add({
        'item': 'Pastillas de Freno',
        'risk': 'Medio',
        'reason': 'Se detecta desgaste avanzado por fricción acumulada.',
        'icon': 'eject',
        'color': '0xFFFF9800',
      });
    }

    // 3. Sistema de Inyección / Bujías (Periodo cada 15,000km cada vez más frecuente con intensidad alta)
    int sparkLife = (totalKms % 15000);
    if (sparkLife > 13000 * (1/wearFactor)) {
      issues.add({
        'item': 'Bujías / Inyección',
        'risk': 'Medio',
        'reason': 'Posible pérdida de eficiencia en la combustión detectada.',
        'icon': 'bolt',
        'color': '0xFFFF9800',
      });
    }

    return issues;
  }
}
