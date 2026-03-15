import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // --- Auth ---
  User? get currentUser => client.auth.currentUser;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // --- Database ---
  Future<List<Map<String, dynamic>>> getVehicles() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    
    return await client
        .from('vehiculos')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<int> getVehicleMileage(String vehicleId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final data = await client
        .from('vehiculos')
        .select('kms')
        .eq('id', vehicleId)
        .eq('user_id', userId)
        .single();

    final kmsValue = data['kms'];
    if (kmsValue is int) return kmsValue;
    if (kmsValue is double) return kmsValue.toInt();
    if (kmsValue is String) return int.tryParse(kmsValue) ?? 0;
    return 0;
  }

  Future<void> updateVehicleKms(String vehicleId, int kms) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client
        .from('vehiculos')
        .update({'kms': kms})
        .eq('id', vehicleId)
        .eq('user_id', userId);
  }

  Future<Map<String, dynamic>> createVehicle({
    required String userId,
    required String marca,
    required String modelo,
    required String apodo,
    required int kms,
    required String imagePath,
  }) async {
    return await client
        .from('vehiculos')
        .insert({
          'user_id': userId,
          'marca': marca,
          'modelo': modelo,
          'apodo': apodo,
          'kms': kms,
          'image_path': imagePath,
        })
        .select()
        .single();
  }

  Future<void> updateMaintenanceDates(String vehicleId, Map<String, String?> dates) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client
        .from('vehiculos')
        .update(dates)
        .eq('id', vehicleId)
        .eq('user_id', userId);
  }

  // --- Telemetría e Historial ---
  Future<void> saveRoute({
    required String vehicleId,
    required String? origin,
    required String? destination,
    required double distance,
    required int durationSeconds,
    required double fuelEstimated,
    required double costEstimated,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final data = {
      'user_id': userId,
      'vehiculo_id': vehicleId,
      'origen': origin,
      'destino': destination,
      'distancia': distance,
      'duracion': durationSeconds.toString(),
      'consumo_estimado': fuelEstimated,
      'costo_estimado': costEstimated,
    };

    try {
      await client.from('rutas_historial').insert(data);
    } catch (e) {
      if (e is PostgrestException) {
        if (e.message.contains('consumo_estimado')) {
          final safeData = Map<String, dynamic>.from(data);
          safeData.remove('consumo_estimado');
          await client.from('rutas_historial').insert(safeData);
          return;
        }
        // Manejar cualquier columna faltante
        final RegExp regExp = RegExp(r"Could not find the '(\w+)' column");
        final match = regExp.firstMatch(e.message);
        if (match != null) {
          final missingColumn = match.group(1);
          final safeData = Map<String, dynamic>.from(data);
          safeData.remove(missingColumn);
          await client.from('rutas_historial').insert(safeData);
          return;
        }
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRouteHistory(String vehicleId) async {
    return await client
        .from('rutas_historial')
        .select()
        .eq('vehiculo_id', vehicleId)
        // La tabla de historial suele tener un campo creado automáticamente.
        // Si tu tabla usa otro nombre (p.ej. created_at), ajusta aquí.
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats(String vehicleId) async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    return await client
        .from('rutas_historial')
        .select()
        .eq('vehiculo_id', vehicleId)
        .gte('created_at', weekAgo)
        .order('created_at', ascending: false);
  }

  // --- Gastos ---
  Future<List<Map<String, dynamic>>> getExpenses(String vehicleId) async {
    return await client
        .from('gastos')
        .select()
        .eq('vehiculo_id', vehicleId)
        .order('fecha', ascending: false);
  }

  Future<void> addExpense({
    required String vehicleId,
    required String categoria,
    required double monto,
    String? descripcion,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client.from('gastos').insert({
      'user_id': userId,
      'vehiculo_id': vehicleId,
      'categoria': categoria,
      'monto': monto,
      'descripcion': descripcion,
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client
        .from('gastos')
        .delete()
        .eq('id', expenseId)
        .eq('user_id', userId);
  }

  // --- Storage ---
  Future<String> getSignedUrl(String bucket, String path, {int expiresIn = 3600}) async {
    return await client.storage.from(bucket).createSignedUrl(path, expiresIn);
  }
}
