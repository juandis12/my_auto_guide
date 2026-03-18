class MaintenanceConfig {
  final String title;
  final int cycleDays;

  MaintenanceConfig({required this.title, required this.cycleDays});
}

class MaintenanceConfigService {
  static final MaintenanceConfigService _instance = MaintenanceConfigService._internal();
  factory MaintenanceConfigService() => _instance;
  MaintenanceConfigService._internal();

  final Map<String, int> _cycles = {
    'cadena': 15,
    'filtro': 90,
    'aceite': 25,
    'soat': 365,
    'tecno': 365,
  };

  final Map<String, int> _kmsCycles = {
    'cadena': 500,
    'filtro': 5000,
    'aceite': 3000,
  };

  int getCycle(String key) => _cycles[key] ?? 30;
  
  int getKmsCycle(String key) => _kmsCycles[key] ?? 5000;
  
  Map<String, int> getAllCycles() => _cycles;
}
