// =============================================================================
// glass_text_field.dart — CAMPO DE TEXTO ESTILO CRISTAL APPLE (HIG)
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/logic/performance_guard.dart';

class GlassTextField extends StatefulWidget {
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
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isFocused) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = Theme.of(context).primaryColor;

    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.50);

    return PerformanceGuard.adaptiveBlur(
      borderRadius: BorderRadius.circular(18),
      fallbackColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.04),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _isFocused
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.80))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.50)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isFocused
                ? primaryAccent.withValues(alpha: 0.80)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.10)),
            width: _isFocused ? 1.5 : 1.0,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: primaryAccent.withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
            letterSpacing: -0.1,
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _isFocused ? primaryAccent : hintColor,
              fontSize: 14,
              letterSpacing: -0.1,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused ? primaryAccent : hintColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
