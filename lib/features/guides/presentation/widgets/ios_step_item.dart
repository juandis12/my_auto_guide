import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_apple_theme.dart';

/// Elemento interactivo de checklist de pasos estilo Apple Reminders / Health
class IosStepItem extends StatelessWidget {
  final int index;
  final String text;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onToggle;
  final Widget? extraContent;

  const IosStepItem({
    super.key,
    required this.index,
    required this.text,
    required this.isCompleted,
    required this.accentColor,
    required this.onToggle,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (isCompleted)
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.15 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppAppleTheme.glassBlurSigma,
            sigmaY: AppAppleTheme.glassBlurSigma,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isCompleted
                          ? accentColor.withValues(alpha: 0.12)
                          : const Color(0xFF1E293B).withValues(alpha: 0.6))
                      : (isCompleted
                          ? accentColor.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.85)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCompleted
                        ? accentColor.withValues(alpha: 0.4)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05)),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Botón de Check Circular Interactivo estilo iOS
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? accentColor
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.04)),
                            border: Border.all(
                              color: isCompleted
                                  ? accentColor
                                  : (isDark ? Colors.white30 : Colors.black26),
                              width: 1.8,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '$index',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w600,
                                  color: isDark
                                      ? (isCompleted ? Colors.white70 : Colors.white)
                                      : (isCompleted ? Colors.black54 : Colors.black87),
                                  decoration:
                                      isCompleted ? TextDecoration.lineThrough : null,
                                  decorationColor: accentColor.withValues(alpha: 0.6),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (extraContent != null) ...[
                      const SizedBox(height: 12),
                      extraContent!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
