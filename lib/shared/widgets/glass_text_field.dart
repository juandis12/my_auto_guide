import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/logic/performance_guard.dart';
import '../../core/theme/app_apple_theme.dart';

/// Campo de entrada de texto estilo Apple HIG Glassmorphism
/// Utiliza desfoque pesado (sigma: 20) y bordes traslúcidos con acento azul/cian
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = Theme.of(context).colorScheme.primary;

    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(18),
      fallbackColor: isDark
          ? AppAppleTheme.midnightSurface.withValues(alpha: 0.80)
          : Colors.white.withValues(alpha: 0.85),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppAppleTheme.glassBlurSigma,
            sigmaY: AppAppleTheme.glassBlurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppAppleTheme.midnightSurface.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? AppAppleTheme.electricCyan.withValues(alpha: 0.20)
                    : AppAppleTheme.electricBlue.withValues(alpha: 0.15),
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                labelText: label,
                labelStyle: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black54,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(
                  icon,
                  color: isDark ? primaryAccent : AppAppleTheme.electricBlue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
