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

    _rpmAnimation = Tween<double>(begin: 0.15, end: 0.92).animate(
      CurvedAnimation(parent: _rpmController, curve: Curves.easeInOutCubic),
    );

    // 3. Pulso de neón
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
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

          // Contenido Central: Tacómetro + Silueta BMW M4 + Escaneo Láser
          AnimatedBuilder(
            animation: Listenable.merge([_scanAnimation, _rpmAnimation, _pulseAnimation]),
            builder: (context, child) {
              final double rpmVal = _rpmAnimation.value;
              final double scanVal = _scanAnimation.value;
              final double pulseVal = _pulseAnimation.value;
              final int speedDisplay = (rpmVal * 190).round();

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Anillo / Tacómetro M-Performance
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Custom Painter del Tacómetro
                        CustomPaint(
                          size: const Size(260, 260),
                          painter: _TachometerPainter(
                            progress: rpmVal,
                            pulse: pulseVal,
                          ),
                        ),

                        // Silueta BMW M4 Coupé con Laser Scan
                        CustomPaint(
                          size: const Size(180, 110),
                          painter: _BmwM4SilhouettePainter(
                            scanProgress: scanVal,
                            pulse: pulseVal,
                          ),
                        ),

                        // Velocidad Digital y Badge M
                        Positioned(
                          bottom: 24,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$speedDisplay',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFF00E5FF),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.electric_bolt_rounded,
                                    size: 13,
                                    color: Color(0xFF00E5FF),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'KM/H • SYS READY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.6,
                                      color: Color(0xFF00E5FF),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Barra de Carga Neón M-Power
                  Container(
                    width: 200,
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
                            colors: [
                              Color(0xFF00E5FF), // Cyan M
                              Color(0xFF2979FF), // Blue M
                              Color(0xFFFF1744), // Red M
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFF00E5FF),
                              blurRadius: 10,
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
                      color: Colors.white.withValues(alpha: 0.9),
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
    if (progress < 0.40) {
      return 'INICIALIZANDO TELEMETRÍA...';
    } else if (progress < 0.75) {
      return 'SINCRONIZANDO GARAJE Y SENSORES...';
    } else {
      return 'DIAGNÓSTICO IA LISTO • ACCEDIENDO';
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

/// CustomPainter para el Tacómetro M-Performance
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

    // 2. Arco activo iluminado con gradiente M-Power
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
        stops: [0.0, 0.45, 0.78, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
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
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;

    const int totalTicks = 18;
    for (int i = 0; i <= totalTicks; i++) {
      final double angle = startAngle + (sweepTotal * (i / totalTicks));
      final double innerR = radius - (i % 3 == 0 ? 15 : 8);
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

/// CustomPainter para la silueta icónica del BMW M4 Coupé con Rayo Láser
class _BmwM4SilhouettePainter extends CustomPainter {
  final double scanProgress;
  final double pulse;

  _BmwM4SilhouettePainter({required this.scanProgress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height * 0.75;
    final double ox = (size.width - w) / 2;
    final double oy = (size.height - h) / 2 - 10;

    // 1. Contorno exterior fiel al BMW M4 Coupé
    final bodyPath = Path();

    // Splitter delantero bajo
    bodyPath.moveTo(ox + w * 0.03, oy + h * 0.82);
    // Talonera frontal
    bodyPath.lineTo(ox + w * 0.08, oy + h * 0.82);
    // Arco de rueda delantera M-Sport
    bodyPath.arcToPoint(
      Offset(ox + w * 0.28, oy + h * 0.82),
      radius: Radius.circular(w * 0.10),
      clockwise: false,
    );
    // Faldón lateral aerodinámico
    bodyPath.lineTo(ox + w * 0.68, oy + h * 0.82);
    // Arco de rueda trasera ensanchada
    bodyPath.arcToPoint(
      Offset(ox + w * 0.88, oy + h * 0.82),
      radius: Radius.circular(w * 0.10),
      clockwise: false,
    );
    // Difusor trasero M y salidas de escape
    bodyPath.lineTo(ox + w * 0.98, oy + h * 0.80);
    bodyPath.lineTo(ox + w * 0.99, oy + h * 0.58);
    // Alerón trasero Ducktail integrado del BMW M4
    bodyPath.lineTo(ox + w * 0.97, oy + h * 0.44);
    bodyPath.lineTo(ox + w * 0.93, oy + h * 0.42);
    // Luneta trasera Fastback
    bodyPath.lineTo(ox + w * 0.72, oy + h * 0.16);
    // Techo de fibra de carbono con canal central (Double Bubble)
    bodyPath.lineTo(ox + w * 0.52, oy + h * 0.13);
    bodyPath.lineTo(ox + w * 0.38, oy + h * 0.14);
    // Pilar A y Parabrisas bajo agresivo
    bodyPath.lineTo(ox + w * 0.22, oy + h * 0.42);
    // Capó largo con abultamiento Powerdome característico del M4
    bodyPath.lineTo(ox + w * 0.07, oy + h * 0.52);
    // Riñones verticales y frontal afilado
    bodyPath.lineTo(ox + w * 0.02, oy + h * 0.66);
    bodyPath.close();

    // 2. Ventanas y Hofmeister Kink (Firma de diseño BMW)
    final windowPath = Path();
    windowPath.moveTo(ox + w * 0.25, oy + h * 0.44);
    windowPath.lineTo(ox + w * 0.38, oy + h * 0.20);
    windowPath.lineTo(ox + w * 0.68, oy + h * 0.20);
    // Hofmeister Kink
    windowPath.lineTo(ox + w * 0.73, oy + h * 0.44);
    windowPath.close();

    // Resplandor y Relleno Neón
    final bodyGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.12 * pulse)
      ..style = PaintingStyle.fill;

    final bodyStrokePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final innerLinePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.50 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Ruedas M con Rines de Estrella
    final wheelPaint = Paint()
      ..color = const Color(0xFF2979FF).withValues(alpha: 0.7 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(bodyPath, bodyGlowPaint);
    canvas.drawPath(bodyPath, bodyStrokePaint);
    canvas.drawPath(windowPath, innerLinePaint);

    // Rines delanteros y traseros
    canvas.drawCircle(Offset(ox + w * 0.18, oy + h * 0.82), w * 0.07, wheelPaint);
    canvas.drawCircle(Offset(ox + w * 0.78, oy + h * 0.82), w * 0.07, wheelPaint);

    // Línea de Escaneo Láser Vertical
    final double laserX = ox + (w * scanProgress);
    final laserPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.95),
          const Color(0xFFFF1744).withValues(alpha: 0.95),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(laserX - 2, oy, 4, h + 15))
      ..strokeWidth = 3.0;

    canvas.drawLine(
      Offset(laserX, oy - 6),
      Offset(laserX, oy + h + 12),
      laserPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BmwM4SilhouettePainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress || oldDelegate.pulse != pulse;
}
