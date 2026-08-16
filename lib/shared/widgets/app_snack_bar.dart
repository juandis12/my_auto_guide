// =============================================================================
// app_snack_bar.dart — NOTIFICACIONES FLOTANTES ESTILO CÁPSULA IOS (APPLE HIG)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSnackBar {
  const AppSnackBar._();

  /// Muestra una notificación flotante estilo cápsula iOS con respuesta háptica.
  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
    Color? backgroundColor,
    bool floating = true,
  }) {
    // 🍎 Respuesta Háptica inmediata al mostrar notificación
    HapticFeedback.lightImpact();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark
            ? const Color(0xFF1C1C1E).withValues(alpha: 0.92)
            : const Color(0xFF2C2C2E).withValues(alpha: 0.90));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
        ),
        action: action,
        duration: duration ?? const Duration(seconds: 3),
        backgroundColor: bg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      ),
    );
  }
}
