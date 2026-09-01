import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_apple_theme.dart';

/// Selector deslizante con estética Apple HIG (Cupertino Segmented Control con Glassmorphism)
class IosSegmentedHeader extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSegmentChanged;
  final List<String> segments;

  const IosSegmentedHeader({
    super.key,
    required this.selectedIndex,
    required this.onSegmentChanged,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppAppleTheme.glassBlurSigma,
          sigmaY: AppAppleTheme.glassBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.65)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: selectedIndex,
            backgroundColor: Colors.transparent,
            thumbColor: isDark
                ? const Color(0xFF2563EB).withValues(alpha: 0.9)
                : Colors.white,
            padding: const EdgeInsets.all(2),
            children: {
              for (int i = 0; i < segments.length; i++)
                i: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        i == 0
                            ? Icons.shield_outlined
                            : Icons.play_circle_outline_rounded,
                        size: 17,
                        color: selectedIndex == i
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        segments[i],
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: selectedIndex == i ? FontWeight.w700 : FontWeight.w500,
                          color: selectedIndex == i
                              ? (isDark ? Colors.white : (i == 0 ? Colors.white : Colors.black87))
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
            },
            onValueChanged: (int? val) {
              if (val != null) {
                onSegmentChanged(val);
              }
            },
          ),
        ),
      ),
    );
  }
}
