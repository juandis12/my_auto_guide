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
    final data = await client
        .from('vehiculos')
        .select('kms')
        .eq('id', vehicleId)
        .single();
    return data['kms'] as int;
  }

  Future<void> updateVehicleKms(String vehicleId, int kms) async {
    await client
        .from('vehiculos')
        .update({'kms': kms})
        .eq('id', vehicleId);
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
    await client
        .from('vehiculos')
        .update(dates)
        .eq('id', vehicleId);
  }

  // --- Storage ---
  Future<String> getSignedUrl(String bucket, String path, {int expiresIn = 3600}) async {
    return await client.storage.from(bucket).createSignedUrl(path, expiresIn);
  }
}
