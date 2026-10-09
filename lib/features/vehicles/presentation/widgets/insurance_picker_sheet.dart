import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/insurance_catalog_service.dart';
import '../../../../core/theme/app_apple_theme.dart';
import '../../domain/models/insurance_company_model.dart';

/// Modal Bottom Sheet con diseño Apple HIG / Cupertino para seleccionar la
/// Aseguradora Todo Riesgo del vehículo (automóviles y motocicletas).
class InsurancePickerSheet {
  static Future<InsuranceCompany?> show({
    required BuildContext context,
    required String? currentId,
    required bool isMoto,
    String title = 'Aseguradora Todo Riesgo',
    String confirmButtonText = 'Listo',
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opciones =
        InsuranceCatalogService.getInsurersForSelection(isMoto: isMoto);

    final String effectiveId = currentId ?? InsuranceCatalogService.noneId;
    int initialIndex = opciones.indexWhere((o) => o.id == effectiveId);
    if (initialIndex < 0) initialIndex = 0;
    int tempIndex = initialIndex;

    return showModalBottomSheet<InsuranceCompany>(
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
              height: 360,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.97),
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
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Handle superior de arrastre
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 38,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Barra de cabecera balanceada
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
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
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop(opciones[tempIndex]);
                            },
                            child: Text(
                              confirmButtonText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF035880),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rueda de selección Cupertino
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: FixedExtentScrollController(
                          initialItem: initialIndex,
                        ),
                        itemExtent: 46,
                        magnification: 1.12,
                        useMagnifier: true,
                        selectionOverlay: Container(
                          decoration: BoxDecoration(
                            color: (isDark
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF035880))
                                .withValues(alpha: 0.08),
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: (isDark
                                        ? const Color(0xFF38BDF8)
                                        : const Color(0xFF035880))
                                    .withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                          ),
                        ),
                        childCount: opciones.length,
                        onSelectedItemChanged: (int index) {
                          tempIndex = index;
                        },
                        itemBuilder: (context, index) {
                          final company = opciones[index];
                          final isNone =
                              company.id == InsuranceCatalogService.noneId;

                          return Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isNone
                                        ? Icons.shield_outlined
                                        : Icons.verified_user_rounded,
                                    size: 17,
                                    color: isNone
                                        ? (isDark ? Colors.white38 : Colors.black38)
                                        : const Color(0xFF035880),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      company.name,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: isNone
                                            ? FontWeight.w500
                                            : FontWeight.w600,
                                        color: isNone
                                            ? (isDark
                                                ? Colors.white54
                                                : Colors.black45)
                                            : (isDark
                                                ? Colors.white
                                                : const Color(0xFF035880)),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
