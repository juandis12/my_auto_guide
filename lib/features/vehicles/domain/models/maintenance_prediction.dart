class MaintenancePrediction {
  final String item;
  final String reason;
  final String risk;
  final bool isCritical;

  const MaintenancePrediction({
    required this.item,
    required this.reason,
    required this.risk,
    this.isCritical = false,
  });

  factory MaintenancePrediction.fromMap(Map<String, dynamic> map) {
    final risk = map['risk']?.toString() ?? 'Bajo';
    return MaintenancePrediction(
      item: map['item']?.toString() ?? 'Mantenimiento General',
      reason: map['reason']?.toString() ?? '',
      risk: risk,
      isCritical: risk.toUpperCase().contains('ALTO') || risk.toUpperCase().contains('CRÍTICO'),
    );
  }

  static List<MaintenancePrediction> fromList(List<dynamic> list) {
    return list.map((e) => MaintenancePrediction.fromMap(e as Map<String, dynamic>)).toList();
  }
}
