import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_apple_theme.dart';

/// Modal Bottom Sheet con CupertinoDatePicker estilo iOS nativo (Rueda deslizable de fecha)
class IosCupertinoDateSheet {
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
    String title = 'Seleccionar Fecha',
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime tempDate = initialDate;
    final now = DateTime.now();

    final max = maximumDate ?? DateTime(now.year + 2, 12, 31);
    final min = minimumDate ?? DateTime(now.year - 5, 1, 1);

    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppAppleTheme.glassBlurSigma,
              sigmaY: AppAppleTheme.glassBlurSigma,
            ),
            child: Container(
              height: 340,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.94)
                    : Colors.white.withValues(alpha: 0.96),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Barra de cabecera estilo iOS (Cancelar / Título / Listo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(ctx).pop(tempDate),
                          child: const Text(
                            'Listo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rueda de fecha Cupertino
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate.isAfter(max)
                          ? max
                          : (initialDate.isBefore(min) ? min : initialDate),
                      minimumDate: min,
                      maximumDate: max,
                      onDateTimeChanged: (DateTime newDate) {
                        tempDate = DateTime(newDate.year, newDate.month, newDate.day);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
