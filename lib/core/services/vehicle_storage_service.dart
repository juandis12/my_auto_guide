import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class VehicleStorageLogicException implements Exception {
  final String message;
  VehicleStorageLogicException(this.message);
  @override
  String toString() => message;
}

class VehicleStorageService {
  static final VehicleStorageService _instance = VehicleStorageService._internal();
  factory VehicleStorageService() => _instance;
  VehicleStorageService._internal();

  final SupabaseClient _supabase = SupabaseService().client;
  final String _bucketName = 'vehiculos-docs';

  /// Obtiene o genera una URL firmada cacheada para un archivo
  Future<String?> getSignedUrl(String? path, Map<String, dynamic> cacheMap) async {
    if (path == null || path.isEmpty) return null;

    final cached = cacheMap[path];
    if (cached != null) {
      final expireDate = DateTime.parse(cached['expires_at']);
      // Retorna el cache si es válido por al menos 5 días más
      if (expireDate.isAfter(DateTime.now().add(const Duration(days: 5)))) {
        return cached['signed_url'];
      }
    }

    try {
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(path, 31536000); // 1 año (365 días en segundos)
      
      cacheMap[path] = {
        'signed_url': signedUrl,
        'expires_at': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      };
      return signedUrl;
    } catch (e) {
      return null;
    }
  }

  /// Lista el contenido de una carpeta
  Future<List<FileObject>> listFolder(String folder) async {
    try {
      return await _supabase.storage.from(_bucketName).list(
            path: folder,
            searchOptions: const SearchOptions(
              limit: 100,
              sortBy: SortBy(column: 'name', order: 'asc'),
            ),
          );
    } catch (e) {
      return [];
    }
  }

  /// Sube un documento en binario
  Future<String> uploadBinary(String path, dynamic bytes) async {
    try {
      await _supabase.storage.from(_bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: false),
      );
      return path;
    } catch (e) {
      throw VehicleStorageLogicException('Error al subir el documento: $e');
    }
  }

  /// Elimina un archivo del storage
  Future<void> deleteDocument(String path) async {
    try {
      await _supabase.storage.from(_bucketName).remove([path]);
    } catch (e) {
      throw VehicleStorageLogicException('Error al eliminar el documento: $e');
    }
  }
}
