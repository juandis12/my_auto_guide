
import 'vehicle_performance_logic.dart';

class FuelEfficiencyLogic {
  /// Calcula el porcentaje de eficiencia comparando consumo real vs ideal.
  /// 100% significa que el usuario consume exactamente lo que el modelo promete.
  /// > 100% significa que es más eficiente que el estándar.
  static double calculateEfficiencyScore({
    required double actualKm,
    required double actualFuelGallons,
    required String modelName,
    bool isCar = false,
  }) {
    if (actualKm <= 0 || actualFuelGallons <= 0) return 0.0;
    
    final idealYield = VehiclePerformanceLogic.getKmPerGalon(modelName, isCar: isCar);
    final actualYield = actualKm / actualFuelGallons;
    
    return (actualYield / idealYield) * 100.0;
  }

  /// Calcula el ahorro (o gasto extra) en COP comparado con el estándar.
  static double calculateSavings({
    required double actualKm,
    required double actualFuelGallons,
    required String modelName,
    bool isCar = false,
    double pricePerGalon = 15500,
  }) {
    final idealYield = VehiclePerformanceLogic.getKmPerGalon(modelName, isCar: isCar);
    final idealFuelNeeded = actualKm / idealYield;
    
    // Si idealFuelNeeded > actualFuelGallons, el usuario ahorró combustible.
    final gallonsSaved = idealFuelNeeded - actualFuelGallons;
    
    return gallonsSaved * pricePerGalon;
  }

  /// Retorna un mensaje descriptivo basado en el score de eficiencia.
  static String getEfficiencyLabel(double score) {
    if (score >= 110) return "Conducción Ultra-Eficiente 💡";
    if (score >= 95) return "Eficiencia Óptima ✅";
    if (score >= 80) return "Eficiencia Promedio 📈";
    return "Alto Consumo Detectado ⚠️";
  }
}
