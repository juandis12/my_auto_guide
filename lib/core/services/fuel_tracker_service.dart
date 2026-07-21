// =============================================================================
// fuel_tracker_service.dart — SERVICIO DE BITÁCORA DE TANQUEO Y RENDIMIENTO
// =============================================================================
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/expenses/domain/models/fuel_log_model.dart';

class FuelTrackerService {
  static final FuelTrackerService _instance = FuelTrackerService._internal();
  factory FuelTrackerService() => _instance;
  FuelTrackerService._internal();

  final _supabase = Supabase.instance.client;

  String _localKey(String vehiculoId) => 'fuel_logs_$vehiculoId';

  /// Cargar historial de tanqueos
  Future<List<FuelLogModel>> getLogs(String vehiculoId) async {
    List<FuelLogModel> logs = [];

    // 1. Intentar cargar de Supabase
    try {
      final response = await _supabase
          .from('tanqueos')
          .select()
          .eq('vehiculo_id', vehiculoId)
          .order('kms_actuales', ascending: false);
      
      logs = (response as List).map((json) => FuelLogModel.fromJson(json)).toList();
      await _cacheLocal(vehiculoId, logs);
      return logs;
    } catch (e) {
      debugPrint('Aviso: Cargando tanqueos de caché local ($e)');
    }

    // 2. Fallback a SharedPreferences local
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_localKey(vehiculoId));
      if (str != null && str.isNotEmpty) {
        final List list = jsonDecode(str);
        logs = list.map((json) => FuelLogModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error leyendo tanqueos locales: $e');
    }

    return logs;
  }

  /// Agregar un nuevo registro de tanqueo
  Future<bool> addLog(FuelLogModel log) async {
    // 1. Guardar localmente
    final currentLogs = await getLogs(log.vehiculoId);
    currentLogs.insert(0, log);
    currentLogs.sort((a, b) => b.kmsActuales.compareTo(a.kmsActuales));
    await _cacheLocal(log.vehiculoId, currentLogs);

    // 2. Intentar sync con Supabase
    try {
      await _supabase.from('tanqueos').upsert(log.toJson());
    } catch (e) {
      debugPrint('Aviso: Tanqueo guardado offline en dispositivo ($e)');
    }

    return true;
  }

  /// Guardar en almacenamiento local del teléfono
  Future<void> _cacheLocal(String vehiculoId, List<FuelLogModel> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = logs.map((l) => l.toJson()).toList();
      await prefs.setString(_localKey(vehiculoId), jsonEncode(listJson));
    } catch (e) {
      debugPrint('Error guardando tanqueos en SharedPreferences: $e');
    }
  }

  /// Calcular métricas de rendimiento (Km/Galón y Costo/Km)
  Map<String, double> calculateMetrics(List<FuelLogModel> logs) {
    if (logs.length < 2) {
      return {
        'kmPerGallon': 0.0,
        'costPerKm': 0.0,
        'totalSpent': logs.isNotEmpty ? logs.first.montoCop : 0.0,
      };
    }

    // Ordenar de más antiguo a más reciente
    final sorted = List<FuelLogModel>.from(logs)..sort((a, b) => a.kmsActuales.compareTo(b.kmsActuales));

    double totalKms = sorted.last.kmsActuales - sorted.first.kmsActuales;
    double totalGallons = 0.0;
    double totalCost = 0.0;

    for (int i = 1; i < sorted.length; i++) {
      totalGallons += sorted[i].galones;
      totalCost += sorted[i].montoCop;
    }

    double kmPerGallon = totalGallons > 0 ? (totalKms / totalGallons) : 0.0;
    double costPerKm = totalKms > 0 ? (totalCost / totalKms) : 0.0;

    return {
      'kmPerGallon': kmPerGallon,
      'costPerKm': costPerKm,
      'totalSpent': totalCost,
    };
  }
}
