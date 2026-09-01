import 'package:flutter/material.dart';

/// Anillo de salud interactivo estilo Apple Watch / Fitness Rings
class IosHealthGauge extends StatelessWidget {
  final double percentage; // 0.0 a 1.0
  final double size;
  final double strokeWidth;
  final String label;
  final bool showLabel;

  const IosHealthGauge({
    super.key,
    required this.percentage,
    this.size = 54,
    this.strokeWidth = 5.5,
    this.label = '',
    this.showLabel = true,
  });

  Color get _statusColor {
    if (percentage <= 0.0) return const Color(0xFFF43F5E); // Vencido (Rose red)
    if (percentage < 0.25) return const Color(0xFFFB923C); // Crítico (Orange)
    if (percentage < 0.50) return const Color(0xFFFBBF24); // Advertencia (Amber)
    return const Color(0xFF10B981); // Saludable (Emerald green)
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clampedPct = percentage.clamp(0.0, 1.0);
    final displayInt = (clampedPct * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: clampedPct,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
              ),
              Center(
                child: Text(
                  percentage <= 0 ? '0%' : '$displayInt%',
                  style: TextStyle(
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel && label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ],
    );
  }
}
