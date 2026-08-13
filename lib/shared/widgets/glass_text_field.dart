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
        ? Colors.white.withAlpha(153)
        : Colors.black.withAlpha(153);

    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(16),
      fallbackColor: isDark
          ? Colors.white.withAlpha(20)
          : Colors.black.withAlpha(13),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha(26)
                : Colors.black.withAlpha(26),
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
