// =============================================================================
// glass_text_field.dart — CAMPO DE TEXTO CON GLASSMORPHISM (APPLE HIG)
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/logic/performance_guard.dart';
import '../../core/theme/app_apple_theme.dart';

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
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(16),
      fallbackColor: isDark
          ? const Color(0xFF0F172A).withValues(alpha: 0.75)
          : Colors.white.withValues(alpha: 0.85),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppAppleTheme.midnightSurface.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppAppleTheme.glassBorder
                : AppAppleTheme.glassBorderLight,
            width: 1.2,
          ),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            labelText: label,
            labelStyle: TextStyle(color: hintColor),
            border: InputBorder.none,
            prefixIcon: Icon(icon, color: hintColor),
          ),
        ),
      ),
    );
  }
}
