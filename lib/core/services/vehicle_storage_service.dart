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

  /// Vigencia de las URLs firmadas de documentos privados.
  static const Duration _signedUrlTtl = Duration(hours: 12);

  /// Margen antes del vencimiento a partir del cual se renueva la URL cacheada.
  static const Duration _signedUrlRenewMargin = Duration(hours: 1);

  /// Obtiene o genera una URL firmada cacheada para un archivo
  Future<String?> getSignedUrl(
    String? path,
    Map<String, dynamic> cacheMap, {
    Duration ttl = _signedUrlTtl,
  }) async {
    if (path == null || path.isEmpty) return null;

    final cached = cacheMap[path];
    if (cached != null) {
      final expireDate = DateTime.parse(cached['expires_at']);
      // Retorna el cache solo si aún queda margen de vigencia
      if (expireDate.isAfter(DateTime.now().add(_signedUrlRenewMargin))) {
        return cached['signed_url'];
      }
    }

    try {
      final signedUrl = await _supabase.storage
          .from(_bucketName)
          .createSignedUrl(path, ttl.inSeconds);

      cacheMap[path] = {
        'signed_url': signedUrl,
        'expires_at': DateTime.now().add(ttl).toIso8601String(),
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

  /// Sube un documento en binario (con sobrescritura/upsert automática)
  Future<String> uploadBinary(String path, dynamic bytes, {bool upsert = true}) async {
    try {
      await _supabase.storage.from(_bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(upsert: upsert),
      );
      return path;
    } catch (e) {
      throw VehicleStorageLogicException('Error al subir el documento: $e');
    }
  }

  /// Elimina un archivo del storage
  Future<void> deleteDocument(String path) async {
    try {
      final res = await _supabase.storage.from(_bucketName).remove([path]);
      if (res.isEmpty) {
        // En Supabase, si no tienes permisos o si ya no existe, devuelve vacío.
        // Si la foto/pdf "ya no existe", le permitiremos pasar silenciosamente 
        // a la UI para que limpie el Caché Inconsistente de PostgreSQL.
      }
    } catch (e) {
      throw VehicleStorageLogicException('Error al eliminar el documento: $e');
    }
  }
}
