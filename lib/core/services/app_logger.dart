// =============================================================================
// app_logger.dart - LOGGER CENTRALIZADO SEGURO (VULN-09 Fix)
// =============================================================================
import 'package:flutter/foundation.dart';

class AppLogger {
  static const _sensitiveFields = [
    'cedula', 'password', 'token', 'fcm_token', 'supabase_key',
    'lat', 'lng', 'latitude', 'longitude',
  ];

  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void error(String context, dynamic e, [StackTrace? st]) {
    if (kDebugMode) {
      debugPrint('[ERROR] Error en $context');
      if (st != null) debugPrint(st.toString());
    } else {
      debugPrint('[ERROR] Error en $context (detalles omitidos en produccion)');
    }
  }

  static void gps(String message) {
    if (kDebugMode) debugPrint('[GPS] $message');
  }

  static void network(String message) {
    if (kDebugMode) {
      var filtered = message;
      for (final field in _sensitiveFields) {
        filtered = filtered.replaceAll(
          RegExp(field + '["\']?\\s*[:=]\\s*["\']?[^"\' &,}\\s]+', caseSensitive: false),
          field + ': [REDACTED]',
        );
      }
      debugPrint('[NET] $filtered');
    }
  }

  static void sync(String context, {int? count, String? id}) {
    if (kDebugMode) {
      final detail = count != null
          ? ' ($count items)'
          : (id != null ? ' (id presente)' : '');
      debugPrint('[SYNC] $context$detail');
    }
  }
}