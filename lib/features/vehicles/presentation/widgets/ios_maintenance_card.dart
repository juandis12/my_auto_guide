import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_apple_theme.dart';
import 'ios_cupertino_date_sheet.dart';
import 'ios_health_gauge.dart';

/// Tarjeta de parametrización de mantenimiento estilo Apple Inset Grouped
class IosMaintenanceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime? date;
  final ValueChanged<DateTime> onDateChanged;
  final TextEditingController? kmController;
  final double currentKms;
  final double healthPercentage;
  final VoidCallback? onScan;
  final bool isLegalDoc; // Si es SOAT o Tecnomecánica

  const IosMaintenanceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.date,
    required this.onDateChanged,
    this.kmController,
    this.currentKms = 0.0,
    required this.healthPercentage,
    this.onScan,
    this.isLegalDoc = false,
  });

  String _formatDate(DateTime? d) {
    if (d == null) return 'Seleccionar fecha';
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  void _applyKmOffset(double offset) {
    if (kmController == null) return;
    double currentVal = double.tryParse(kmController!.text) ?? currentKms;
    double newVal = (currentVal + offset).clamp(0.0, 999999.0);
    kmController!.text = newVal.toStringAsFixed(0);
  }

  void _useCurrentKm() {
    if (kmController == null) return;
    kmController!.text = currentKms.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera de la tarjeta: Icono + Título + Anillo de salud
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF38BDF8),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IosHealthGauge(
                      percentage: healthPercentage,
                      size: 48,
                      strokeWidth: 4.5,
                      showLabel: false,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Selector de Fecha estilo iOS Pill
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await IosCupertinoDateSheet.show(
                            context: context,
                            title: 'Fecha de $title',
                            initialDate: date ?? now,
                            maximumDate: isLegalDoc
                                ? DateTime(now.year + 2, 12, 31)
                                : now,
                            minimumDate: DateTime(now.year - 5, 1, 1),
                          );
                          if (picked != null) {
                            onDateChanged(picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: date == null
                                  ? const Color(0xFFF43F5E).withValues(alpha: 0.5)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.black.withValues(alpha: 0.06)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: date == null
                                    ? const Color(0xFFF43F5E)
                                    : const Color(0xFF38BDF8),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _formatDate(date),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: date == null
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: date == null
                                        ? const Color(0xFFF43F5E)
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.unfold_more_rounded,
                                size: 18,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (onScan != null) ...[
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onScan,
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  const Color(0xFF38BDF8).withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.document_scanner_rounded,
                                color: Color(0xFF38BDF8),
                                size: 20,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Escanear',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Sección de Kilometraje y Chips Rápidos (solo para mantenimientos mecánicos)
                if (kmController != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Kilometraje al momento del mantenimiento:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input de Kilometraje
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      controller: kmController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Ej. 15400',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                        suffixText: 'km',
                        suffixStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Chips de Kilometraje Rápido (Apple Quick Pills)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildQuickChip(
                          label: 'Usar actual (${currentKms.toStringAsFixed(0)} km)',
                          onTap: _useCurrentKm,
                          isPrimary: true,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip(
                          label: '+1,000 km',
                          onTap: () => _applyKmOffset(1000),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip(
                          label: '+3,000 km',
                          onTap: () => _applyKmOffset(3000),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChip(
                          label: '+5,000 km',
                          onTap: () => _applyKmOffset(5000),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
            color: isPrimary
                ? const Color(0xFF38BDF8)
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
