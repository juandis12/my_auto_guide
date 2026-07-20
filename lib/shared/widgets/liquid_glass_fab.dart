// =============================================================================
// liquid_glass_fab.dart — BOTÓN FLOTANTE ESTILO LIQUID GLASS
// =============================================================================
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

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
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            // Sutil animación de brillo pulsante en los bordes
            final double glowValue = _pulseController.value;
            
            return Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C6FF).withOpacity(0.25 + (glowValue * 0.1)),
                    blurRadius: 15 + (glowValue * 5),
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0072FF).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      // Combinación de gradiente translúcido para el efecto de cristal líquido
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.blue.shade900.withOpacity(0.35),
                                Colors.purple.shade900.withOpacity(0.25),
                              ]
                            : [
                                Colors.blue.shade400.withOpacity(0.55),
                                Colors.purple.shade300.withOpacity(0.40),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25 + (glowValue * 0.15)),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 20,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 1.5),
                              )
                            ],
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
