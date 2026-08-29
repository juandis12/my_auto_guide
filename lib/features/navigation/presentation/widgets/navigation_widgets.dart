import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Chip informativo para distancia, tiempo o consumo en el mapa.
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const InfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de información balanceada para diálogos de resumen.
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: isDark ? Colors.blueAccent : Colors.blueGrey, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Widget de éxito animado (Checkmark) tras finalizar ruta.
class SuccessCheckmark extends StatefulWidget {
  const SuccessCheckmark({super.key});

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _check;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _check = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeInOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5)],
          ),
          child: AnimatedBuilder(
            animation: _check,
            builder: (context, child) {
              return CustomPaint(painter: _CheckPainter(_check.value));
            },
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = ui.Path();
    path.moveTo(size.width * 0.28, size.height * 0.52);
    path.lineTo(size.width * 0.45, size.height * 0.7);
    path.lineTo(size.width * 0.72, size.height * 0.38);

    final pathMetrics = path.computeMetrics();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final extractPath = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Modal de Resumen de Viaje con estilo Apple / Neón Glassmorphism
class TripSummarySheet extends StatelessWidget {
  final double distanceKm;
  final int durationSeconds;
  final double avgSpeedKmH;
  final double maxSpeedKmH;
  final double fuelGallons;
  final double estimatedCost;
  final String destinationName;
  final VoidCallback onDismiss;

  const TripSummarySheet({
    super.key,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgSpeedKmH,
    required this.maxSpeedKmH,
    required this.fuelGallons,
    required this.estimatedCost,
    required this.destinationName,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mins = (durationSeconds / 60).floor();
    final secs = durationSeconds % 60;
    final timeStr = mins > 60
        ? '${(mins / 60).floor()}h ${mins % 60}m'
        : (mins > 0 ? '${mins}m ${secs}s' : '${secs}s');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14171F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, -10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Icono de Éxito y Título
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF87).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00FF87),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Recorrido Finalizado!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destinationName.isNotEmpty ? destinationName : 'Recorrido Libre',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Rejilla de Métricas Principales
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryMetric(
                        icon: Icons.route_rounded,
                        label: 'Distancia',
                        value: '${distanceKm.toStringAsFixed(1)} km',
                        color: const Color(0xFF00C6FF),
                        isDark: isDark,
                      ),
                    ),
                    Container(width: 1, height: 40, color: isDark ? Colors.white12 : Colors.black12),
                    Expanded(
                      child: _SummaryMetric(
                        icon: Icons.timer_outlined,
                        label: 'Tiempo',
                        value: timeStr,
                        color: const Color(0xFF00FF87),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryMetric(
                        icon: Icons.av_timer_rounded,
                        label: 'Vel. Promedio',
                        value: '${avgSpeedKmH.toStringAsFixed(0)} km/h',
                        color: const Color(0xFF2979FF),
                        isDark: isDark,
                      ),
                    ),
                    Container(width: 1, height: 40, color: isDark ? Colors.white12 : Colors.black12),
                    Expanded(
                      child: _SummaryMetric(
                        icon: Icons.speed_rounded,
                        label: 'Vel. Máxima',
                        value: '${maxSpeedKmH.toStringAsFixed(0)} km/h',
                        color: const Color(0xFFFF3B30),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                if (fuelGallons > 0 || estimatedCost > 0) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          icon: Icons.local_gas_station_rounded,
                          label: 'Consumo Est.',
                          value: '${fuelGallons.toStringAsFixed(2)} gal',
                          color: Colors.orangeAccent,
                          isDark: isDark,
                        ),
                      ),
                      Container(width: 1, height: 40, color: isDark ? Colors.white12 : Colors.black12),
                      Expanded(
                        child: _SummaryMetric(
                          icon: Icons.payments_rounded,
                          label: 'Costo Est.',
                          value: '\$${estimatedCost > 1000 ? (estimatedCost / 1000).toStringAsFixed(1) : estimatedCost.toStringAsFixed(0)}k',
                          color: const Color(0xFF30D158),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón Finalizar / Aceptar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Aceptar y Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}
