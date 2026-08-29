import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OdometerHistoryService {
  static final OdometerHistoryService _instance =
      OdometerHistoryService._internal();
  factory OdometerHistoryService() => _instance;
  OdometerHistoryService._internal();

  /// Registra una nueva lectura de odómetro con timestamp
  Future<void> recordOdometerReading(String vehicleId, int kms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'odometer_history_$vehicleId';
      final rawList = prefs.getStringList(key) ?? [];

      final now = DateTime.now();
      final newEntry = jsonEncode({
        'date': now.toIso8601String(),
        'kms': kms,
      });

      // Añadir y guardar hasta 60 lecturas históricas
      rawList.add(newEntry);
      if (rawList.length > 60) {
        rawList.removeAt(0);
      }

      await prefs.setStringList(key, rawList);
      await prefs.setString(
          'last_km_check_$vehicleId', now.toIso8601String());
      debugPrint(
          'OdometerHistoryService: Registrado $kms km para $vehicleId el $now');
    } catch (e) {
      debugPrint('Error registrando lectura de odómetro: $e');
    }
  }

  /// Obtiene el historial ordenado de lecturas de kilometraje
  Future<List<Map<String, dynamic>>> getHistory(String vehicleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'odometer_history_$vehicleId';
      final rawList = prefs.getStringList(key) ?? [];

      final List<Map<String, dynamic>> history = [];
      for (final item in rawList) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          history.add(decoded);
        } catch (_) {}
      }
      return history;
    } catch (e) {
      debugPrint('Error obteniendo historial de odómetro: $e');
      return [];
    }
  }

  /// Calcula el promedio de kilómetros recorridos por día (Km/Día)
  Future<double> getAverageKmPerDay(String vehicleId,
      {bool isCar = false}) async {
    final defaultUsage = isCar ? 35.0 : 25.0;
    try {
      final history = await getHistory(vehicleId);
      if (history.length < 2) {
        return defaultUsage;
      }

      // Tomar primer y último registro con diferencia de al menos 12 horas
      final first = history.first;
      final last = history.last;

      final firstDate = DateTime.tryParse(first['date']?.toString() ?? '');
      final lastDate = DateTime.tryParse(last['date']?.toString() ?? '');

      if (firstDate == null || lastDate == null) return defaultUsage;

      final int firstKm = (first['kms'] as num?)?.toInt() ?? 0;
      final int lastKm = (last['kms'] as num?)?.toInt() ?? 0;

      final hoursDiff = lastDate.difference(firstDate).inHours;
      if (hoursDiff < 12) {
        return defaultUsage;
      }

      final daysDiff = hoursDiff / 24.0;
      final kmDiff = (lastKm - firstKm).clamp(0, 1000000);

      final avg = kmDiff / daysDiff;
      // Limitar el promedio a un rango sensato (mínimo 5 km/día, máximo 1500 km/día)
      return avg.clamp(5.0, 1500.0);
    } catch (e) {
      debugPrint('Error calculando promedio diario de km: $e');
      return defaultUsage;
    }
  }
}
