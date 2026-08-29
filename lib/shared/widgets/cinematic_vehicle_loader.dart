import 'dart:math' as math;
import 'package:flutter/material.dart';

class CinematicVehicleLoader extends StatefulWidget {
  final String statusText;
  const CinematicVehicleLoader({
    super.key,
    this.statusText = 'SINCRONIZANDO MY AUTO GUIDE...',
  });

  @override
  State<CinematicVehicleLoader> createState() => _CinematicVehicleLoaderState();
}

class _CinematicVehicleLoaderState extends State<CinematicVehicleLoader>
    with TickerProviderStateMixin {
  late AnimationController _scanController;
  late AnimationController _rpmController;
  late AnimationController _pulseController;

  late Animation<double> _scanAnimation;
  late Animation<double> _rpmAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Escaneo láser continuo
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // 2. Tacómetro / RPM Acelerando
    _rpmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rpmAnimation = Tween<double>(begin: 0.1, end: 0.88).animate(
      CurvedAnimation(parent: _rpmController, curve: Curves.easeInOutCubic),
    );

    // 3. Pulso de neón
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _rpmController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0A0C10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo con malla de cuadrícula cibernética
          Positioned.fill(
            child: CustomPaint(
              painter: _CyberGridPainter(),
            ),
          ),

          // Contenido Central: Tacómetro + Silueta + Escaneo
          AnimatedBuilder(
            animation: Listenable.merge([_scanAnimation, _rpmAnimation, _pulseAnimation]),
            builder: (context, child) {
              final double rpmVal = _rpmAnimation.value;
              final double scanVal = _scanAnimation.value;
              final double pulseVal = _pulseAnimation.value;
              final int speedDisplay = (rpmVal * 160).round();

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Anillo / Tacómetro de Inicio
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Custom Painter del Tacómetro
                        CustomPaint(
                          size: const Size(240, 240),
                          painter: _TachometerPainter(
                            progress: rpmVal,
                            pulse: pulseVal,
                          ),
                        ),

                        // Silueta del Vehículo con Laser Scan
                        CustomPaint(
                          size: const Size(140, 100),
                          painter: _VehicleSilhouettePainter(
                            scanProgress: scanVal,
                            pulse: pulseVal,
                          ),
                        ),

                        // Velocidad Digital en el Centro Inferior
                        Positioned(
                          bottom: 28,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$speedDisplay',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFF00E5FF),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                'KM/H • SYS OK',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Barra de Carga Neón
                  Container(
                    width: 180,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: rpmVal,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5FF), Color(0xFF2979FF), Color(0xFF30D158)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF00E5FF),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Texto de Estado Diagnóstico Dinámico
                  Text(
                    _getStatusText(rpmVal),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.satellite_alt_rounded, size: 13, color: Color(0xFF30D158)),
                      SizedBox(width: 6),
                      Text(
                        'MY AUTO GUIDE TELEMETRY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Color(0xFF30D158),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getStatusText(double progress) {
    if (progress < 0.35) {
      return 'INICIALIZANDO SENSORES...';
    } else if (progress < 0.70) {
      return 'SINCRONIZANDO TELEMETRÍA...';
    } else {
      return 'CALIBRANDO DIAGNÓSTICO IA...';
    }
  }
}

/// CustomPainter para el fondo de cuadrícula cibernética
class _CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Viñeta radial oscura
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF0A0C10).withValues(alpha: 0.95),
        ],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter para el Tacómetro Digital (Arco de RPM con Neon Glow)
class _TachometerPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _TachometerPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    const double startAngle = math.pi * 0.75;
    const double sweepTotal = math.pi * 1.5;

    // 1. Arco base oscuro
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      basePaint,
    );

    // 2. Arco activo iluminado con gradiente
    final activePaint = Paint()
      ..shader = const SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepTotal,
        colors: [
          Color(0xFF00E5FF),
          Color(0xFF2979FF),
          Color(0xFFFF9100),
          Color(0xFFFF1744),
        ],
        stops: [0.0, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * progress,
      false,
      activePaint,
    );

    // 3. Ticks de revoluciones
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;

    const int totalTicks = 16;
    for (int i = 0; i <= totalTicks; i++) {
      final double angle = startAngle + (sweepTotal * (i / totalTicks));
      final double innerR = radius - (i % 4 == 0 ? 14 : 8);
      final double outerR = radius - 4;

      final p1 = Offset(center.dx + innerR * math.cos(angle), center.dy + innerR * math.sin(angle));
      final p2 = Offset(center.dx + outerR * math.cos(angle), center.dy + outerR * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TachometerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pulse != pulse;
}

/// CustomPainter para la silueta del vehículo con rayo láser de escaneo
class _VehicleSilhouettePainter extends CustomPainter {
  final double scanProgress;
  final double pulse;

  _VehicleSilhouettePainter({required this.scanProgress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujar contorno deportivo de vehículo
    final path = Path();
    final double w = size.width;
    final double h = size.height * 0.7;
    final double ox = (size.width - w) / 2;
    final double oy = (size.height - h) / 2 - 8;

    path.moveTo(ox + w * 0.05, oy + h * 0.75);
    path.lineTo(ox + w * 0.18, oy + h * 0.75);
    // Rueda delantera arco
    path.arcToPoint(
      Offset(ox + w * 0.34, oy + h * 0.75),
      radius: Radius.circular(w * 0.08),
      clockwise: false,
    );
    path.lineTo(ox + w * 0.66, oy + h * 0.75);
    // Rueda trasera arco
    path.arcToPoint(
      Offset(ox + w * 0.82, oy + h * 0.75),
      radius: Radius.circular(w * 0.08),
      clockwise: false,
    );
    path.lineTo(ox + w * 0.95, oy + h * 0.75);
    // Parte trasera
    path.lineTo(ox + w * 0.96, oy + h * 0.45);
    // Techo
    path.lineTo(ox + w * 0.68, oy + h * 0.15);
    path.lineTo(ox + w * 0.38, oy + h * 0.15);
    // Parabrisas
    path.lineTo(ox + w * 0.18, oy + h * 0.45);
    path.lineTo(ox + w * 0.04, oy + h * 0.52);
    path.close();

    // Silueta con resplandor neón
    final bodyGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.12 * pulse)
      ..style = PaintingStyle.fill;

    final bodyStrokePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.75 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, bodyGlowPaint);
    canvas.drawPath(path, bodyStrokePaint);

    // Línea de escaneo láser vertical
    final double laserX = ox + (w * scanProgress);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.9),
          const Color(0xFF30D158).withValues(alpha: 0.9),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(laserX - 2, oy, 4, h + 10))
      ..strokeWidth = 3.0;

    canvas.drawLine(
      Offset(laserX, oy - 4),
      Offset(laserX, oy + h + 8),
      laserPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VehicleSilhouettePainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress || oldDelegate.pulse != pulse;
}
