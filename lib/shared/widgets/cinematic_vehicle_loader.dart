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

/// CustomPainter para la silueta icónica en perspectiva 3/4 del BMW M4 Coupé
class _BmwM4SilhouettePainter extends CustomPainter {
  final double scanProgress;
  final double pulse;

  _BmwM4SilhouettePainter({required this.scanProgress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double ox = 0;
    final double oy = 0;

    // Colores y pinturas
    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.14 * pulse)
      ..style = PaintingStyle.fill;

    final primaryStroke = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.95 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final detailStroke = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final accentStroke = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.85 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final wheelFill = Paint()
      ..color = const Color(0xFF0A1526).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final wheelStroke = Paint()
      ..color = const Color(0xFF2979FF).withValues(alpha: 0.9 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // ─── 1. SILUETA EXTERIOR PRINCIPAL (BMW M4 3/4 VIEW) ───
    final outline = Path();
    // Splitter frontal izquierdo
    outline.moveTo(ox + w * 0.08, oy + h * 0.76);
    // Labio inferior y splitter
    outline.lineTo(ox + w * 0.54, oy + h * 0.77);
    // Arco rueda delantera
    outline.arcToPoint(
      Offset(ox + w * 0.68, oy + h * 0.65),
      radius: Radius.circular(w * 0.12),
      clockwise: false,
    );
    // Talonera lateral aerodinámica M
    outline.lineTo(ox + w * 0.84, oy + h * 0.68);
    // Arco rueda trasera
    outline.arcToPoint(
      Offset(ox + w * 0.92, oy + h * 0.61),
      radius: Radius.circular(w * 0.08),
      clockwise: false,
    );
    // Parachoques trasero / difusor
    outline.lineTo(ox + w * 0.94, oy + h * 0.54);
    // Maletero y Alerón trasero GT
    outline.lineTo(ox + w * 0.93, oy + h * 0.44);
    outline.lineTo(ox + w * 0.86, oy + h * 0.40);
    // Luneta trasera inclinada Fastback
    outline.lineTo(ox + w * 0.76, oy + h * 0.32);
    // Techo Coupé M con canal aerodinámico central
    outline.lineTo(ox + w * 0.65, oy + h * 0.28);
    outline.lineTo(ox + w * 0.44, oy + h * 0.31);
    // Pilar A y Parabrisas delantero
    outline.lineTo(ox + w * 0.32, oy + h * 0.42);
    // Capó esculpido Powerdome hacia el frontal
    outline.lineTo(ox + w * 0.16, oy + h * 0.50);
    // Punta del morro y caída de riñones
    outline.lineTo(ox + w * 0.08, oy + h * 0.58);
    outline.lineTo(ox + w * 0.06, oy + h * 0.68);
    outline.close();

    canvas.drawPath(outline, glowPaint);
    canvas.drawPath(outline, primaryStroke);

    // ─── 2. RIÑONES VERTICALES ICÓNICOS BMW M4 (G82 DUAL KIDNEYS) ───
    // Riñón izquierdo (más frontal)
    final leftKidney = Path();
    leftKidney.moveTo(ox + w * 0.14, oy + h * 0.54);
    leftKidney.lineTo(ox + w * 0.21, oy + h * 0.54);
    leftKidney.lineTo(ox + w * 0.22, oy + h * 0.74);
    leftKidney.lineTo(ox + w * 0.13, oy + h * 0.73);
    leftKidney.close();
    canvas.drawPath(leftKidney, primaryStroke);

    // Riñón derecho (perspectiva 3/4)
    final rightKidney = Path();
    rightKidney.moveTo(ox + w * 0.23, oy + h * 0.54);
    rightKidney.lineTo(ox + w * 0.31, oy + h * 0.55);
    rightKidney.lineTo(ox + w * 0.32, oy + h * 0.73);
    rightKidney.lineTo(ox + w * 0.24, oy + h * 0.74);
    rightKidney.close();
    canvas.drawPath(rightKidney, primaryStroke);

    // Barras horizontales internas de los riñones
    canvas.drawLine(Offset(ox + w * 0.14, oy + h * 0.60), Offset(ox + w * 0.21, oy + h * 0.60), detailStroke);
    canvas.drawLine(Offset(ox + w * 0.14, oy + h * 0.67), Offset(ox + w * 0.215, oy + h * 0.67), detailStroke);
    canvas.drawLine(Offset(ox + w * 0.235, oy + h * 0.60), Offset(ox + w * 0.31, oy + h * 0.60), detailStroke);
    canvas.drawLine(Offset(ox + w * 0.24, oy + h * 0.67), Offset(ox + w * 0.315, oy + h * 0.67), detailStroke);

    // ─── 3. FAROS LÁSER AFILADOS M (ANGULAR HEADLIGHTS) ───
    // Faro izquierdo
    final leftHeadlight = Path();
    leftHeadlight.moveTo(ox + w * 0.08, oy + h * 0.53);
    leftHeadlight.lineTo(ox + w * 0.13, oy + h * 0.54);
    leftHeadlight.lineTo(ox + w * 0.10, oy + h * 0.58);
    leftHeadlight.close();
    canvas.drawPath(leftHeadlight, accentStroke);

    // Faro derecho (más largo hacia el lateral)
    final rightHeadlight = Path();
    rightHeadlight.moveTo(ox + w * 0.33, oy + h * 0.54);
    rightHeadlight.lineTo(ox + w * 0.48, oy + h * 0.53);
    rightHeadlight.lineTo(ox + w * 0.45, oy + h * 0.59);
    rightHeadlight.lineTo(ox + w * 0.35, oy + h * 0.59);
    rightHeadlight.close();
    canvas.drawPath(rightHeadlight, primaryStroke);

    // DRLs LED en faro derecho
    canvas.drawLine(Offset(ox + w * 0.36, oy + h * 0.56), Offset(ox + w * 0.43, oy + h * 0.55), accentStroke);

    // ─── 4. LÍNEAS DEL CAPÓ Y POWERDOME ───
    canvas.drawLine(Offset(ox + w * 0.18, oy + h * 0.53), Offset(ox + w * 0.32, oy + h * 0.43), detailStroke);
    canvas.drawLine(Offset(ox + w * 0.26, oy + h * 0.53), Offset(ox + w * 0.39, oy + h * 0.43), detailStroke);
    canvas.drawLine(Offset(ox + w * 0.44, oy + h * 0.52), Offset(ox + w * 0.50, oy + h * 0.44), detailStroke);

    // ─── 5. CABINA, VENTANAS Y HOFMEISTER KINK ───
    // Parabrisas
    final windshield = Path();
    windshield.moveTo(ox + w * 0.34, oy + h * 0.43);
    windshield.lineTo(ox + w * 0.45, oy + h * 0.33);
    windshield.lineTo(ox + w * 0.63, oy + h * 0.31);
    windshield.lineTo(ox + w * 0.58, oy + h * 0.43);
    windshield.close();
    canvas.drawPath(windshield, detailStroke);

    // Ventana lateral con Hofmeister Kink
    final sideWindow = Path();
    sideWindow.moveTo(ox + w * 0.60, oy + h * 0.42);
    sideWindow.lineTo(ox + w * 0.66, oy + h * 0.31);
    sideWindow.lineTo(ox + w * 0.77, oy + h * 0.36);
    // Kink
    sideWindow.lineTo(ox + w * 0.78, oy + h * 0.43);
    sideWindow.close();
    canvas.drawPath(sideWindow, detailStroke);

    // Espejo retrovisor M con doble brazo
    final mirror = Path();
    mirror.moveTo(ox + w * 0.58, oy + h * 0.41);
    mirror.lineTo(ox + w * 0.65, oy + h * 0.40);
    mirror.lineTo(ox + w * 0.64, oy + h * 0.45);
    mirror.lineTo(ox + w * 0.58, oy + h * 0.45);
    mirror.close();
    canvas.drawPath(mirror, primaryStroke);

    // ─── 6. ALERÓN TRASERO GT (REAR SPOILER) ───
    final spoiler = Path();
    spoiler.moveTo(ox + w * 0.83, oy + h * 0.36);
    spoiler.lineTo(ox + w * 0.92, oy + h * 0.35);
    spoiler.lineTo(ox + w * 0.93, oy + h * 0.39);
    spoiler.lineTo(ox + w * 0.84, oy + h * 0.40);
    spoiler.close();
    canvas.drawPath(spoiler, accentStroke);

    // Soportes de alerón
    canvas.drawLine(Offset(ox + w * 0.86, oy + h * 0.40), Offset(ox + w * 0.86, oy + h * 0.43), detailStroke);
    canvas.drawLine(Offset(ox + w * 0.90, oy + h * 0.39), Offset(ox + w * 0.90, oy + h * 0.44), detailStroke);

    // ─── 7. RUEDAS M SPORT EN PERSPECTIVA 3/4 CON RINES MULTIRRADIO ───
    // Rueda delantera (3/4)
    final frontWheelCenter = Offset(ox + w * 0.59, oy + h * 0.67);
    canvas.drawOval(
      Rect.fromCenter(center: frontWheelCenter, width: w * 0.19, height: h * 0.30),
      wheelFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: frontWheelCenter, width: w * 0.19, height: h * 0.30),
      wheelStroke,
    );
    // Radios M rueda delantera
    for (int i = 0; i < 5; i++) {
      final angle = (i * math.pi / 2.5);
      final rx = (w * 0.08) * math.cos(angle);
      final ry = (h * 0.13) * math.sin(angle);
      canvas.drawLine(frontWheelCenter, Offset(frontWheelCenter.dx + rx, frontWheelCenter.dy + ry), detailStroke);
    }

    // Rueda trasera (3/4)
    final rearWheelCenter = Offset(ox + w * 0.87, oy + h * 0.61);
    canvas.drawOval(
      Rect.fromCenter(center: rearWheelCenter, width: w * 0.13, height: h * 0.22),
      wheelFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: rearWheelCenter, width: w * 0.13, height: h * 0.22),
      wheelStroke,
    );
    // Radios M rueda trasera
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2.0);
      final rx = (w * 0.055) * math.cos(angle);
      final ry = (h * 0.09) * math.sin(angle);
      canvas.drawLine(rearWheelCenter, Offset(rearWheelCenter.dx + rx, rearWheelCenter.dy + ry), detailStroke);
    }

    // ─── 8. LÍNEA DE ESCANEO LÁSER VERTICAL CIBERNÉTICA ───
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
      ).createShader(Rect.fromLTWH(laserX - 2, oy, 4, h + 10))
      ..strokeWidth = 2.5;

    canvas.drawLine(
      Offset(laserX, oy + h * 0.15),
      Offset(laserX, oy + h * 0.88),
      laserPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BmwM4SilhouettePainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress || oldDelegate.pulse != pulse;
}
