import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_apple_theme.dart';
import '../../data/models/guide_protocol_model.dart';

/// Tarjeta de protocolo con estética Apple HIG (Frosted Glass, Spring feedback, pill badges y progreso)
class IosProtocolCard extends StatefulWidget {
  final GuideProtocol protocol;
  final int completedStepsCount;
  final VoidCallback onTap;

  const IosProtocolCard({
    super.key,
    required this.protocol,
    required this.completedStepsCount,
    required this.onTap,
  });

  @override
  State<IosProtocolCard> createState() => _IosProtocolCardState();
}

class _IosProtocolCardState extends State<IosProtocolCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSteps = widget.protocol.steps.length;
    final progress = totalSteps > 0 ? (widget.completedStepsCount / totalSteps) : 0.0;
    final isCompleted = widget.completedStepsCount == totalSteps && totalSteps > 0;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: widget.protocol.accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppAppleTheme.glassBlurSigma,
              sigmaY: AppAppleTheme.glassBlurSigma,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.78)
                        : Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark
                          ? widget.protocol.accentColor.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fila Superior: Badge de Categoría e Icono con Glow
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.protocol.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: widget.protocol.accentColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.protocol.icon,
                              color: widget.protocol.accentColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: widget.protocol.accentColor
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        widget.protocol.category.toUpperCase(),
                                        style: TextStyle(
                                          color: widget.protocol.accentColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (widget.completedStepsCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? const Color(0xFF10B981)
                                                  .withValues(alpha: 0.15)
                                              : Colors.blue.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isCompleted
                                              ? 'COMPLETO'
                                              : '${widget.completedStepsCount}/$totalSteps PASOS',
                                          style: TextStyle(
                                            color: isCompleted
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF38BDF8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.protocol.title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black87,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? Colors.white38 : Colors.black26,
                            size: 22,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text(
                        widget.protocol.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Barra de Progreso Discreta estilo iOS
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted
                                ? const Color(0xFF10B981)
                                : widget.protocol.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
