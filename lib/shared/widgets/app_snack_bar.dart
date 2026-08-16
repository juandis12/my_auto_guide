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
    bool floating = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration ?? const Duration(seconds: 4),
        backgroundColor: backgroundColor,
        behavior: floating ? SnackBarBehavior.floating : null,
      ),
    );
  }
}
