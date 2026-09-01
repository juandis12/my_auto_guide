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

  /// Busca manuales en Supabase con fallback a caché local (Offline-First)
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
        queryBuilder = queryBuilder.ilike('model', '%${query.trim()}%');
      }

      final response = await queryBuilder.limit(limit);
      final list = (response as List).map((e) => MotorcycleManual.fromJson(e as Map<String, dynamic>)).toList();

      if (list.isNotEmpty) return list;
    } catch (e) {
      if (kDebugMode) debugPrint('[MANUALS] Supabase query error, fallback a local: $e');
    }

    // Fallback Offline a JSON Local
    final local = await _loadLocalData();
    return local.where((m) {
      final matchMake = make == null || make.isEmpty || make.toLowerCase() == 'todas' || m.make.toLowerCase().contains(make.toLowerCase());
      final matchQuery = query == null || query.isEmpty || m.model.toLowerCase().contains(query.toLowerCase()) || m.year.contains(query);
      return matchMake && matchQuery;
    }).take(limit).toList();
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
