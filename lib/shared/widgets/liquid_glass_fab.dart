import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../core/theme/app_apple_theme.dart';

/// Botón Flotante Estilo Apple HIG Liquid Glass
/// Utiliza desfoque pesado (sigma: 20) y paleta Medianoche Dinámico
class LiquidGlassFAB extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const LiquidGlassFAB({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  State<LiquidGlassFAB> createState() => _LiquidGlassFABState();
}

class _LiquidGlassFABState extends State<LiquidGlassFAB> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: AppAppleTheme.springCurve,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double glowValue = _pulseController.value;
            
            return Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppAppleTheme.electricCyan.withValues(alpha: 0.25 + (glowValue * 0.10)),
                    blurRadius: 16 + (glowValue * 6),
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppAppleTheme.electricBlue.withValues(alpha: 0.20),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppAppleTheme.glassBlurSigma,
                    sigmaY: AppAppleTheme.glassBlurSigma,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppAppleTheme.electricBlue.withValues(alpha: 0.50),
                                AppAppleTheme.midnightSurface.withValues(alpha: 0.70),
                              ]
                            : [
                                AppAppleTheme.electricBlue.withValues(alpha: 0.75),
                                AppAppleTheme.electricBlueLight.withValues(alpha: 0.60),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppAppleTheme.electricCyan.withValues(alpha: 0.30 + (glowValue * 0.15))
                            : Colors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LiquidGlassButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final String label;
  final double? width;
  final double height;
  final double borderRadius;
  final List<Color>? customColors;

  const LiquidGlassButton({
    super.key,
    required this.onTap,
    this.icon,
    required this.label,
    this.width,
    this.height = 48,
    this.borderRadius = 20,
    this.customColors,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: AppAppleTheme.springCurve,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double glowValue = _pulseController.value;
            
            return Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppAppleTheme.electricBlue.withValues(alpha: 0.20 + (glowValue * 0.05)),
                    blurRadius: 12 + (glowValue * 4),
                    spreadRadius: 0.5,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppAppleTheme.glassBlurSigma,
                    sigmaY: AppAppleTheme.glassBlurSigma,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      gradient: LinearGradient(
                        colors: widget.customColors ??
                            (isDark
                                ? [
                                    AppAppleTheme.electricBlue.withValues(alpha: 0.45),
                                    AppAppleTheme.midnightSurface.withValues(alpha: 0.65),
                                  ]
                                : [
                                    AppAppleTheme.electricBlue.withValues(alpha: 0.75),
                                    AppAppleTheme.electricBlueLight.withValues(alpha: 0.60),
                                  ]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppAppleTheme.electricCyan.withValues(alpha: 0.25 + (glowValue * 0.10))
                            : Colors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LiquidGlassIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final double iconSize;

  const LiquidGlassIconButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.size = 38,
    this.iconSize = 18,
  });

  @override
  State<LiquidGlassIconButton> createState() => _LiquidGlassIconButtonState();
}

class _LiquidGlassIconButtonState extends State<LiquidGlassIconButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: AppAppleTheme.springCurve,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final double glowValue = _pulseController.value;
            
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppAppleTheme.electricBlue.withValues(alpha: 0.20 + (glowValue * 0.05)),
                    blurRadius: 10 + (glowValue * 3),
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppAppleTheme.glassBlurSigma,
                    sigmaY: AppAppleTheme.glassBlurSigma,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                AppAppleTheme.electricBlue.withValues(alpha: 0.45),
                                AppAppleTheme.midnightSurface.withValues(alpha: 0.65),
                              ]
                            : [
                                AppAppleTheme.electricBlue.withValues(alpha: 0.75),
                                AppAppleTheme.electricBlueLight.withValues(alpha: 0.60),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppAppleTheme.electricCyan.withValues(alpha: 0.25 + (glowValue * 0.10))
                            : Colors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: widget.iconSize,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
