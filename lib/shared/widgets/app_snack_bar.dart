// =============================================================================
// app_snack_bar.dart — MENSAJES EMERGENTES (SnackBar) CENTRALIZADOS (APPLE HIG)
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/theme/app_apple_theme.dart';

class AppSnackBar {
  const AppSnackBar._();

  /// Muestra un SnackBar con [message] en el [context] indicado con diseño Apple HIG.
  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
    Color? backgroundColor,
    bool floating = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark
        ? AppAppleTheme.midnightSurfaceElevated.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.95);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: action,
        duration: duration ?? const Duration(seconds: 4),
        backgroundColor: backgroundColor ?? defaultBg,
        behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? AppAppleTheme.glassBorder
                : AppAppleTheme.glassBorderLight,
            width: 1.0,
          ),
        ),
        elevation: 8,
      ),
    );
  }
}
