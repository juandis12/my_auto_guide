import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../services/database.dart';
import '../services/supabase_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final AppDatabase _db = AppDatabase();
  final SupabaseService _supabase = SupabaseService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void initialize() {
    // Escuchar cambios en conectividad
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final List<ConnectivityResult> connectivityResults = results;
      final ConnectivityResult result = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;
      if (result != ConnectivityResult.none) {
        // Hay conexión, intentar sincronizar
        syncPendingData();
      }
    });


  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      final ConnectivityResult result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (result == ConnectivityResult.none) return false;

      // Verificar conectividad real haciendo un ping DNS rápido sin llamadas HTTP a Supabase
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking internet: $e');
      return false;
    }
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) {
      debugPrint('SyncService: Ya hay una sincronización en curso. Ignorando...');
      return;
    }

    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    if (result == ConnectivityResult.none) return;

    _isSyncing = true;
    try {
      debugPrint('SyncService: Iniciando sincronización de datos pendientes...');
      await _syncPendingRoutes();
      await _syncPendingKmsUpdates();
      await _syncPendingExpenses();
      debugPrint('SyncService: Sincronización completada exitosamente.');
    } catch (e) {
      debugPrint('SyncService: Error global en sincronización: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Método genérico para procesar cualquier cola de base de datos local
  Future<void> _processQueue<T>({
    required String logName,
    required Future<List<T>> Function() fetchItems,
    required Future<void> Function(T item) syncItem,
    required Future<void> Function(T item) markAsSynced,
  }) async {
    final items = await fetchItems();
    if (items.isEmpty) return;

    debugPrint('Pendientes $logName: ${items.length}');
    for (final item in items) {
      try {
        await syncItem(item);
        await markAsSynced(item);
        debugPrint('$logName sincronizado (ID: ${(item as Map)['id']})');
      } catch (e) {
        debugPrint('Error sincronizando $logName (ID: ${(item as Map)['id']}): $e');
      }
    }
  }

  Future<void> _syncPendingRoutes() async {
    await _processQueue<Map<String, dynamic>>(
      logName: 'Rutas',
      fetchItems: _db.getPendingRoutes,
      syncItem: (route) async {
        await _supabase.saveRoute(
          vehicleId: route['vehicleId'],
          origin: route['originName'],
          destination: route['destinationName'],
          distance: (route['distanceKm'] as num?)?.toDouble() ?? 0.0,
          durationSeconds: route['durationSeconds'] ?? 0,
          fuelEstimated: (route['consumoGalones'] as num?)?.toDouble() ?? 0.0,
          costEstimated: (route['costoEstimado'] as num?)?.toDouble() ?? 0.0,
          velocidadMax: (route['velocidad_max'] as num?)?.toDouble(),
          velocidadProm: (route['velocidad_prom'] as num?)?.toDouble(),
          points: route['viaPuntos'] != null ? jsonDecode(route['viaPuntos']) : null,
        );
      },
      markAsSynced: (route) => _db.markRouteAsSynced(route['id']),
    );
  }

  Future<void> _syncPendingKmsUpdates() async {
    await _processQueue<Map<String, dynamic>>(
      logName: 'KMS Updates',
      fetchItems: _db.getPendingKmsUpdates,
      syncItem: (update) async {
        final kmsToAddRaw = update['kmsToAdd'];
        final kmsToAdd = kmsToAddRaw is int
            ? kmsToAddRaw
            : int.tryParse(kmsToAddRaw?.toString() ?? '') ?? 0;

        final currentKms = await _supabase.getVehicleMileage(update['vehicleId']);
        final newKms = currentKms + kmsToAdd;

        await _supabase.updateVehicleKms(update['vehicleId'], newKms);
      },
      markAsSynced: (update) => _db.markKmsUpdateAsSynced(update['id']),
    );
  }

  Future<void> _syncPendingExpenses() async {
    await _processQueue<Map<String, dynamic>>(
      logName: 'Gastos',
      fetchItems: _db.getPendingExpenses,
      syncItem: (expense) async {
        await _supabase.addExpense(
          vehicleId: expense['vehicleId'],
          categoria: expense['categoria'],
          monto: expense['monto'],
          descripcion: expense['descripcion'],
        );
      },
      markAsSynced: (expense) => _db.markExpenseAsSynced(expense['id']),
    );
  }

  // Método para guardar ruta de forma offline-first
  Future<void> saveRouteOfflineFirst({
    required String userId,
    required String vehicleId,
    required String originName,
    required String destinationName,
    required double distanceKm,
    required int durationSeconds,
    required double consumoGalones,
    required double costoEstimado,
    double? velocidadMax,
    double? velocidadProm,
    List<dynamic>? viaPuntos,
  }) async {
    final routeData = {
      'userId': userId,
      'vehicleId': vehicleId,
      'originName': originName,
      'destinationName': destinationName,
      'distanceKm': distanceKm,
      'durationSeconds': durationSeconds,
      'consumoGalones': consumoGalones,
      'costoEstimado': costoEstimado,
      'velocidad_max': velocidadMax,
      'velocidad_prom': velocidadProm,
      'viaPuntos': viaPuntos != null ? jsonEncode(viaPuntos) : null,
      'fecha': DateTime.now().toIso8601String(),
      'synced': 0
    };

    debugPrint('SyncService: Guardando ruta localmente (Offline-First)');
    debugPrint(' - Distancia: $distanceKm km');
    debugPrint(' - Fecha: ${routeData['fecha']}');

    // Guardar localmente primero
    await _db.insertPendingRoute(routeData);

    // Intentar sincronizar inmediatamente si hay internet
    if (await hasInternetConnection()) {
      try {
        await _supabase.saveRoute(
          vehicleId: vehicleId,
          origin: originName,
          destination: destinationName,
          distance: distanceKm,
          durationSeconds: durationSeconds,
          fuelEstimated: consumoGalones,
          costEstimated: costoEstimado,
          velocidadMax: velocidadMax,
          velocidadProm: velocidadProm,
          points: viaPuntos,
        );

        // Marcar como sincronizada
        final routes = await _db.getPendingRoutes();
        for (final route in routes) {
          if (route['vehicleId'] == vehicleId &&
              route['fecha'] == routeData['fecha']) {
            await _db.markRouteAsSynced(route['id']);
            break;
          }
        }
      } catch (e) {
        debugPrint('Error sincronizando ruta inmediatamente: $e');
        // Queda pendiente para sincronización posterior
      }
    }
  }

  // Método para actualizar KMS de forma offline-first
  Future<void> updateVehicleKmsOfflineFirst(
      String vehicleId, int kmsToAdd) async {
    // Guardar localmente primero
    await _db.insertPendingKmsUpdate(vehicleId, kmsToAdd);

    // Intentar sincronizar inmediatamente si hay internet
    if (await hasInternetConnection()) {
      try {
        final currentKms = await _supabase.getVehicleMileage(vehicleId);
        final newKms = currentKms + kmsToAdd;
        await _supabase.updateVehicleKms(vehicleId, newKms);

        // Marcar como sincronizada
        final updates = await _db.getPendingKmsUpdates();
        for (final update in updates) {
          if (update['vehicleId'] == vehicleId &&
              update['kmsToAdd'] == kmsToAdd) {
            await _db.markKmsUpdateAsSynced(update['id']);
            debugPrint(
                'KMS update sincronizado inmediatamente: ${update['id']}');
            break;
          }
        }
      } catch (e) {
        debugPrint('Error sincronizando KMS update inmediatamente: $e');
        // Queda pendiente para sincronización posterior
      }
    }
  }

  // Método para guardar gasto de forma offline-first
  Future<void> saveExpenseOfflineFirst({
    required String userId,
    required String vehicleId,
    required String categoria,
    required double monto,
    String? descripcion,
  }) async {
    final expenseData = {
      'userId': userId,
      'vehicleId': vehicleId,
      'categoria': categoria,
      'monto': monto,
      'descripcion': descripcion ?? '',
      'fecha': DateTime.now().toIso8601String(),
      'synced': 0
    };

    debugPrint('SyncService: Guardando gasto localmente (Offline-First)');

    // Guardar localmente primero
    await _db.insertPendingExpense(expenseData);

    // Intentar sincronizar inmediatamente si hay internet
    if (await hasInternetConnection()) {
      try {
        await _syncPendingExpenses();
      } catch (e) {
        debugPrint('Error sincronizando gasto inmediatamente: $e');
      }
    }
  } // FIN saveExpenseOfflineFirst

  // Método para obtener historial combinado (Supabase + Local Pendiente)
  Future<List<Map<String, dynamic>>> getCombinedRouteHistory(String vehicleId) async {
    List<Map<String, dynamic>> combined = [];

    // 1. Obtener de Supabase (si hay internet)
    try {
      if (await hasInternetConnection()) {
        final remote = await _supabase.getRouteHistory(vehicleId);
        combined.addAll(remote);
      }
    } catch (e) {
      debugPrint('SyncService: Error cargando historial remoto: $e');
    }

    // 2. Obtener locales pendientes
    try {
      final pending = await _db.getPendingRoutes();
      final filtered = pending.where((r) => r['vehicleId'] == vehicleId).map((r) {
        // Mapear al formato de Supabase (snake_case) para compatibilidad con la UI
        return {
          'id': 'pending_${r['id']}',
          'user_id': r['userId'],
          'vehiculo_id': r['vehicleId'],
          'origen': r['originName'],
          'destino': r['destinationName'],
          'distancia': r['distanceKm'],
          'duracion': r['durationSeconds']?.toString() ?? '0',
          'consumo_estimado': r['consumoGalones'],
          'costo_estimado': r['costoEstimado'],
          'velocidad_max': r['velocidad_max'],
          'velocidad_prom': r['velocidad_prom'],
          'created_at': r['fecha'],
          'via_puntos': r['viaPuntos'] != null ? jsonDecode(r['viaPuntos']) : null,
          'is_pending': true, // Flag para la UI
        };
      });
      combined.addAll(filtered);
    } catch (e) {
      debugPrint('SyncService: Error cargando rutas locales: $e');
    }

    // 3. Ordenar por fecha (descendente)
    combined.sort((a, b) {
      final dateA = DateTime.tryParse(a['fecha'] ?? a['created_at'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['fecha'] ?? b['created_at'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return combined;
  }
}
