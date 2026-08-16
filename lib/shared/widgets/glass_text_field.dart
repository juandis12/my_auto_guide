// =============================================================================
// glass_text_field.dart — CAMPO DE TEXTO CON GLASSMORPHISM
// =============================================================================
//
// Campo de entrada con efecto de vidrio (adaptativo según la gama del
// dispositivo mediante [PerformanceGuard.adaptiveBlur]) usado en las pantallas
// de autenticación. Antes cada campo repetía el mismo bloque de decoración y
// colores dependientes del tema.
//
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/logic/performance_guard.dart';

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
      sigma: 15.0,
      fallbackColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.12),
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
