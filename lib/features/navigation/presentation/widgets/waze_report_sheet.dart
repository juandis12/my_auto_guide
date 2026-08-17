// =============================================================================
// waze_report_sheet.dart — MODAL GLASSMORPHIC DE REPORTES 1-TAP (ESTILO WAZE)
// =============================================================================
// Permite al conductor o copiloto reportar incidentes en la vía en 1 segundo.
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/waze_community_alerts_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

class WazeReportSheet extends StatelessWidget {
  final double currentLat;
  final double currentLng;

  const WazeReportSheet({
    super.key,
    required this.currentLat,
    required this.currentLng,
  });

  static void show(BuildContext context, {required double lat, required double lng}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => WazeReportSheet(currentLat: lat, currentLng: lng),
    );
  }

  void _sendReport(BuildContext context, WazeIncidentType type, String title) {
    WazeCommunityAlertsService().reportIncident(
      type: type,
      title: title,
      description: 'Reportado por conductor en ruta',
      latitude: currentLat,
      longitude: currentLng,
    );

    Navigator.pop(context);
    AppSnackBar.show(
      context,
      '✅ Reporte registrado en tiempo real: $title',
      backgroundColor: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'REPORTAR EN LA VÍA (1-TAP)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildReportOption(
                    context,
                    icon: Icons.local_police_rounded,
                    label: 'Policía',
                    color: const Color(0xFF0A84FF),
                    onTap: () => _sendReport(context, WazeIncidentType.police, '👮 Retén de Policía / Tránsito'),
                  ),
                  _buildReportOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'Fotomulta',
                    color: const Color(0xFFFF9500),
                    onTap: () => _sendReport(context, WazeIncidentType.radar, '🚨 Cámara / Radar de Fotomulta'),
                  ),
                  _buildReportOption(
                    context,
                    icon: Icons.car_crash_rounded,
                    label: 'Accidente',
                    color: const Color(0xFFFF3B30),
                    onTap: () => _sendReport(context, WazeIncidentType.accident, '🚗 Accidente de Tránsito'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildReportOption(
                    context,
                    icon: Icons.construction_rounded,
                    label: 'Obra / Tráfico',
                    color: const Color(0xFFFFCC00),
                    onTap: () => _sendReport(context, WazeIncidentType.construction, '🚧 Obra en Vía / Tráfico'),
                  ),
                  _buildReportOption(
                    context,
                    icon: Icons.water_drop_rounded,
                    label: 'Inundación',
                    color: const Color(0xFF30D158),
                    onTap: () => _sendReport(context, WazeIncidentType.flooding, '🌧️ Vía Inundada / Mal Estado'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
