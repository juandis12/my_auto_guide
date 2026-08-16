// =============================================================================
// app_snack_bar.dart — MENSAJES EMERGENTES (SnackBar) CENTRALIZADOS
// =============================================================================
//
// Utilidad compartida para mostrar SnackBars con el mismo formato en toda la
// app, evitando repetir el bloque
// `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(...)))`
// en cada pantalla.
//
// =============================================================================

import 'package:flutter/material.dart';

class AppSnackBar {
  const AppSnackBar._();

  /// Muestra un SnackBar con [message] en el [context] indicado.
  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
    Color? backgroundColor,
    bool floating = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: -0.2),
        ),
        action: action,
        duration: duration ?? const Duration(seconds: 4),
        backgroundColor: backgroundColor ?? const Color(0xFF1E293B),
        behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        shape: floating
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  width: 1.0,
                ),
              )
            : null,
      ),
    );
  }
}
