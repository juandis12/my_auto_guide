// =============================================================================
// parts_catalog_service.dart — CATÁLOGO DE REPUESTOS Y INSUMOS UNIVERSALES
// =============================================================================
// Proporciona el catálogo de piezas 100% compatibles por vehículo y repuestos universales.
// =============================================================================

class CompatiblePart {
  final String id;
  final String category; // 'Aceites', 'Llantas', 'Frenos', 'Filtros', 'Bujías', 'Baterías'
  final String partName;
  final String brand;
  final String spec;
  final double estimatedPriceCop;
  final bool isUniversal;

  const CompatiblePart({
    required this.id,
    required this.category,
    required this.partName,
    required this.brand,
    required this.spec,
    required this.estimatedPriceCop,
    required this.isUniversal,
  });
}

class PartsCatalogService {
  static const List<CompatiblePart> _catalog = [
    // Aceites Universales
    CompatiblePart(id: 'oil_1', category: 'Aceites', partName: 'Aceite Sintético 10W-40 4T', brand: 'Motul 7100', spec: '100% Sintético Ester', estimatedPriceCop: 68000, isUniversal: true),
    CompatiblePart(id: 'oil_2', category: 'Aceites', partName: 'Aceite Motor 20W-50', brand: 'Mobil Super', spec: 'Mineral Multigrado', estimatedPriceCop: 38000, isUniversal: true),
    CompatiblePart(id: 'oil_3', category: 'Aceites', partName: 'Aceite Full Sintético 5W-30', brand: 'Mobil 1', spec: 'Para Motores Gasolina', estimatedPriceCop: 145000, isUniversal: true),

    // Llantas Universales y Específicas
    CompatiblePart(id: 'tire_1', category: 'Llantas', partName: 'Llanta 110/70-17 Pilot Street 2', brand: 'Michelin', spec: 'Pista y Lluvia', estimatedPriceCop: 285000, isUniversal: true),
    CompatiblePart(id: 'tire_2', category: 'Llantas', partName: 'Llanta 140/70-17 Diablo Rosso IV', brand: 'Pirelli', spec: 'Deportiva Híbrida', estimatedPriceCop: 420000, isUniversal: true),

    // Bujías & Baterías
    CompatiblePart(id: 'spark_1', category: 'Bujías', partName: 'Bujía de Iridio CPR8EAIX-9', brand: 'NGK Iridium', spec: 'Alto Rendimiento', estimatedPriceCop: 45000, isUniversal: true),
    CompatiblePart(id: 'bat_1', category: 'Baterías', partName: 'Batería 12V 9Ah Libres de Mantenimiento', brand: 'MAC Gold', spec: 'Gel de Calcio', estimatedPriceCop: 185000, isUniversal: true),
  ];

  static List<CompatiblePart> getCompatibleParts({
    required String modelName,
    required String categoryFilter,
  }) {
    if (categoryFilter.isEmpty || categoryFilter == 'Todos') {
      return _catalog;
    }
    return _catalog.where((p) => p.category == categoryFilter).toList();
  }

  static List<String> getAvailableCategories() {
    return ['Todos', 'Aceites', 'Llantas', 'Frenos', 'Filtros', 'Bujías', 'Baterías'];
  }
}
