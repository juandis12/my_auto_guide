// =============================================================================
// secure_storage_service.dart - ALMACENAMIENTO CIFRADO DE CREDENCIALES
// VULN-01 Fix: reemplaza SharedPreferences por Android Keystore / iOS Keychain
// =============================================================================
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );

  static const _kSupabaseUrl = 'secure_supabase_url';
  static const _kSupabaseKey = 'secure_supabase_anon_key';

  Future<void> saveSupabaseCredentials({required String url, required String anonKey}) async {
    await _storage.write(key: _kSupabaseUrl, value: url);
    await _storage.write(key: _kSupabaseKey, value: anonKey);
  }

  Future<String?> getSupabaseUrl() => _storage.read(key: _kSupabaseUrl);
  Future<String?> getSupabaseAnonKey() => _storage.read(key: _kSupabaseKey);
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);
}
