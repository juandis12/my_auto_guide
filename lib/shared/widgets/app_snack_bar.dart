import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_apple_theme.dart';

/// Utilidad compartida para mostrar Notificaciones Flotantes / Dynamic Toast estilo Apple HIG
class AppSnackBar {
  const AppSnackBar._();

  /// Muestra una notificación flotante traslúcida estilo Apple HIG
  static void show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration? duration,
    Color? backgroundColor,
    bool floating = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: Colors.transparent,
        duration: duration ?? const Duration(seconds: 4),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppAppleTheme.glassBlurSigma,
              sigmaY: AppAppleTheme.glassBlurSigma,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: backgroundColor ??
                    (isDark
                        ? AppAppleTheme.midnightSurface.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.80)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? AppAppleTheme.electricCyan.withValues(alpha: 0.30)
                      : Colors.white.withValues(alpha: 0.20),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        action: action,
      ),
    );
  }
}
