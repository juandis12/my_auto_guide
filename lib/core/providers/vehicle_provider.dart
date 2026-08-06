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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
    await _supabaseService.createVehicle(
      userId: vehicleData['user_id'],
      marca: vehicleData['marca'],
      modelo: vehicleData['modelo'],
      apodo: vehicleData['apodo'],
      kms: vehicleData['kms'],
      imagePath: vehicleData['image_path'],
    );
    await loadVehicles(); // Recargar lista
  }

  Future<void> updateVehicleKms(String vehicleId, int kms) async {
    await _supabaseService.updateVehicleKms(vehicleId, kms);
    await loadVehicles();
  }
}
