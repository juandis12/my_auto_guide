
class VehiclePerformanceLogic {
  /// Retorna el cilindraje aproximado extrayendo números del nombre del modelo.
  /// Ej: "MT 15" -> 150, "PULSAR NS 200" -> 200, "VERSYS 650" -> 650.
  static int extractCC(String modelName) {
    final name = modelName.toUpperCase();
    
    // Mapeos específicos para modelos conocidos donde el número no es el CC exacto
    if (name.contains('MT 15') || name.contains('R15') || name.contains('XTZ 150')) return 150;
    if (name.contains('NKD') || name.contains('CRYPTON')) return 110;
    if (name.contains('BOXER')) return 100;
    if (name.contains('N-MAX')) return 155;
    if (name.contains('FZ 2.0')) return 150;

    // Extracción por expresión regular para casos generales
    final regExp = RegExp(r'(\d{3,4})');
    final match = regExp.firstMatch(name);
    
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 125;
    }

    return 125; // Valor por defecto seguro
  }

  /// Retorna el rendimiento estimado en Kilómetros por Galón (KM/GAL).
  static double getKmPerGalon(String modelName, {bool isCar = false}) {
    if (isCar) {
      // Valor promedio para carros de la app (Toyota/Mazda/Chevrolet)
      return 45.0; 
    }

    final cc = extractCC(modelName);

    if (cc <= 110) return 180.0;
    if (cc <= 160) return 135.0;
    if (cc <= 250) return 105.0;
    if (cc <= 450) return 90.0;
    if (cc <= 750) return 70.0;
    
    return 45.0; // Motos de alto cilindraje (>800cc)
  }

  /// Calcula el consumo estimado dado una distancia en kilómetros.
  static double estimateFuelConsumption(double distanceKm, String modelName, {bool isCar = false}) {
    final yield = getKmPerGalon(modelName, isCar: isCar);
    return distanceKm / yield;
  }

  /// Calcula el costo estimado (Asumiendo precio de gasolina actual en Colombia ~15,500 COP).
  static double estimateFuelCost(double gallons, {double pricePerGalon = 15500}) {
    return gallons * pricePerGalon;
  }
}
