import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class VehicleProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();
    try {
      _vehicles = await _supabaseService.getVehicles();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      await _supabaseService.createVehicle(
        userId: vehicleData['user_id'],
        marca: vehicleData['marca'],
        modelo: vehicleData['modelo'],
        apodo: vehicleData['apodo'],
        kms: vehicleData['kms'],
        imagePath: vehicleData['image_path'],
      );
      await loadVehicles(); // Recargar lista
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVehicleKms(String vehicleId, int kms) async {
    try {
      await _supabaseService.updateVehicleKms(vehicleId, kms);
      await loadVehicles();
    } catch (e) {
      rethrow;
    }
  }
}
