import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';
import 'supabase_service.dart';

class VehicleStorageLogicException implements Exception {
  final String message;

  /// Error original que provocó la falla, para no perder el diagnóstico.
  final Object? cause;

  VehicleStorageLogicException(this.message, {this.cause});
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
    } catch (e, stackTrace) {
      AppLogger.error('VehicleStorageService.getSignedUrl($path)', e, stackTrace);
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
    } catch (e, stackTrace) {
      AppLogger.error('VehicleStorageService.listFolder($folder)', e, stackTrace);
      return [];
    }
  }

  /// Sube un documento en binario (con sobrescritura/upsert automática)
  Future<String> uploadBinary(String path, dynamic bytes, {bool upsert = true}) async {
    try {
      await _supabase.storage.from(_bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(upsert: upsert),
      );
      return path;
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        VehicleStorageLogicException('Error al subir el documento: $e',
            cause: e),
        stackTrace,
      );
    }
  }

  /// Elimina un archivo del storage
  Future<void> deleteDocument(String path) async {
    try {
      final res = await _supabase.storage.from(_bucketName).remove([path]);
      if (res.isEmpty) {
        // En Supabase, si no tienes permisos o si ya no existe, devuelve vacío.
        // Se deja pasar para que la UI limpie el caché inconsistente, pero se
        // registra porque también puede indicar un problema de permisos (RLS).
        AppLogger.warning('VehicleStorageService.deleteDocument($path)',
            'Supabase no eliminó ningún archivo (¿no existe o falta permiso?)');
      }
    } catch (e, stackTrace) {
      Error.throwWithStackTrace(
        VehicleStorageLogicException('Error al eliminar el documento: $e',
            cause: e),
        stackTrace,
      );
    }
  }
}
