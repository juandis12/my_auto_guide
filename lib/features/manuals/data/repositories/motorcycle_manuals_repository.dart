import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/motorcycle_manual_model.dart';

class MotorcycleManualsRepository {
  static final MotorcycleManualsRepository _instance = MotorcycleManualsRepository._internal();
  factory MotorcycleManualsRepository() => _instance;
  MotorcycleManualsRepository._internal();

  List<MotorcycleManual> _localCache = [];
  bool _isCacheLoaded = false;

  /// Normaliza una cadena quitando caracteres especiales, tildes, guiones y espacios.
  /// Ej: "NS 200", "NS-200", "ns.200" -> "ns200"
  static String normalizeString(String text) {
    var result = text.toLowerCase();
    result = result
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
    return result.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Evalúa de forma inteligente si un manual o ficha técnica coincide con la consulta
  static bool matchesSmartQuery(MotorcycleManual manual, String? make, String? query) {
    // 1. Validar Filtro de Marca
    if (make != null && make.trim().isNotEmpty && make.toLowerCase() != 'todas') {
      final normMake = normalizeString(make);
      final normManualMake = normalizeString(manual.make);
      if (!normManualMake.contains(normMake) && !normMake.contains(normManualMake)) {
        return false;
      }
    }

    // 2. Validar Búsqueda de Texto Libre
    if (query == null || query.trim().isEmpty) return true;

    final rawQuery = query.trim();
    final normQuery = normalizeString(rawQuery);
    final normMakeModel = normalizeString('${manual.make} ${manual.model} ${manual.year} ${manual.type ?? ''}');

    // Coincidencia directa normalizada (ej: "ns200" en "pulsarns200")
    if (normQuery.isNotEmpty && normMakeModel.contains(normQuery)) {
      return true;
    }

    // Coincidencia por tokens / palabras individuales (ej: "pulsar 200")
    final queryTokens = rawQuery
        .toLowerCase()
        .split(RegExp(r'[\s\-_,.]+'))
        .map((t) => normalizeString(t))
        .where((t) => t.isNotEmpty)
        .toList();

    if (queryTokens.isEmpty) return false;

    // Todos los tokens deben encontrarse en el texto normalizado del manual
    return queryTokens.every((token) => normMakeModel.contains(token));
  }

  /// Carga los datos de manuales locales precargados como fallback offline
  Future<List<MotorcycleManual>> _loadLocalData() async {
    if (_isCacheLoaded && _localCache.isNotEmpty) return _localCache;
    try {
      final jsonString = await rootBundle.loadString('assets/data/motorcycle_manuals.json');
      final List dynamicList = json.decode(jsonString);
      _localCache = dynamicList.map((e) => MotorcycleManual.fromJson(e as Map<String, dynamic>)).toList();
      _isCacheLoaded = true;
      return _localCache;
    } catch (e) {
      if (kDebugMode) debugPrint('[MANUALS] No se pudo cargar JSON local: $e');
      return [];
    }
  }

  /// Busca manuales en Supabase de forma inteligente con fallback a caché local (Offline-First)
  Future<List<MotorcycleManual>> searchManuals({
    String? make,
    String? query,
    int limit = 50,
  }) async {
    try {
      final client = Supabase.instance.client;
      var queryBuilder = client.from('motorcycle_manuals').select();

      if (make != null && make.trim().isNotEmpty && make.toLowerCase() != 'todas') {
        queryBuilder = queryBuilder.ilike('make', '%${make.trim()}%');
      }

      if (query != null && query.trim().isNotEmpty) {
        final rawQ = query.trim();
        final cleanQ = normalizeString(rawQ);
        final spacedQ = rawQ.replaceAllMapped(RegExp(r'([a-zA-Z]+)(\d+)'), (m) => '${m[1]} ${m[2]}');
        final dashedQ = rawQ.replaceAll(RegExp(r'\s+'), '-');

        // Construir variaciones dinámicas para Supabase PostgREST
        final conditions = <String>{
          'model.ilike.%$rawQ%',
          if (cleanQ.isNotEmpty) 'model.ilike.%$cleanQ%',
          if (spacedQ != rawQ) 'model.ilike.%$spacedQ%',
          if (dashedQ != rawQ) 'model.ilike.%$dashedQ%',
          'make.ilike.%$rawQ%',
        }.join(',');

        queryBuilder = queryBuilder.or(conditions);
      }

      final response = await queryBuilder.limit(limit * 2);
      final list = (response as List)
          .map((e) => MotorcycleManual.fromJson(e as Map<String, dynamic>))
          .where((m) => matchesSmartQuery(m, make, query))
          .take(limit)
          .toList();

      if (list.isNotEmpty) return list;
    } catch (e) {
      if (kDebugMode) debugPrint('[MANUALS] Supabase query error, fallback a local: $e');
    }

    // Fallback Offline a JSON Local con búsqueda inteligente
    final local = await _loadLocalData();
    return local
        .where((m) => matchesSmartQuery(m, make, query))
        .take(limit)
        .toList();
  }

  /// Obtiene la ficha técnica específica para la moto actual del usuario
  Future<MotorcycleManual?> getManualForVehicle({
    required String make,
    required String model,
  }) async {
    final results = await searchManuals(make: make, query: model, limit: 5);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }
}
