import 'dart:math';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class AppWidgetLogic {
  static const String androidWidgetName = 'AppWidgetProvider';
  static const String healthWidgetName = 'VehicleStatusWidgetProvider';
  static const String healthListWidgetName = 'VehicleStatusListWidgetProvider';
  
  /// Actualiza los datos visibles en el widget de navegación.
  static Future<void> updateWidget({
    required double distance,
    required bool isTracking,
  }) async {
    try {
      await HomeWidget.saveWidgetData<double>('current_distance', distance);
      await HomeWidget.saveWidgetData<bool>('is_tracking', isTracking);
      
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error en updateWidget: $e');
    }
  }

  /// Actualiza ambos widgets de salud (Estilo Arcos 2x2 y Estilo Lista de Barras Samsung One UI)
  static Future<void> updateHealthWidget({
    required double pctCadena,
    required double pctFiltro,
    required double pctAceite,
    required double pctSoat,
    double pctTecno = 1.0,
  }) async {
    // 1. Renderizar Medidores en Herradura (Samsung One UI Circular Grid 2x2)
    await _renderSamsungArcGauge('widget_aceite', pctAceite, 'Aceite', Icons.water_drop_rounded);
    await _renderSamsungArcGauge('widget_cadena', pctCadena, 'Cadena', Icons.link_rounded);
    await _renderSamsungArcGauge('widget_filtro', pctFiltro, 'Filtro', Icons.air_rounded);
    await _renderSamsungArcGauge('widget_soat', pctSoat, 'SOAT', Icons.description_rounded);

    // 2. Renderizar Barras Horizontales (Samsung One UI Pill List Style)
    await _renderSamsungPillBar('widget_list_aceite', pctAceite, 'Aceite', Icons.water_drop_rounded);
    await _renderSamsungPillBar('widget_list_cadena', pctCadena, 'Cadena', Icons.link_rounded);
    await _renderSamsungPillBar('widget_list_filtro', pctFiltro, 'Filtro', Icons.air_rounded);
    await _renderSamsungPillBar('widget_list_soat', pctSoat, 'SOAT', Icons.description_rounded);
    
    // Actualizar ambos widgets nativos
    try {
      await HomeWidget.updateWidget(androidName: healthWidgetName);
      await HomeWidget.updateWidget(androidName: healthListWidgetName);
    } catch (e) {
      debugPrint('Error actualizando widgets nativos de Android: $e');
    }
  }

  /// Renderiza un medidor de arco / herradura idéntico al widget de batería de Samsung One UI
  static Future<void> _renderSamsungArcGauge(
    String key, double pct, String label, IconData icon,
  ) async {
    final int percent = (pct * 100).round().clamp(0, 100);
    final Color color = percent > 50
        ? const Color(0xFF00E676)  // Samsung Emerald Green
        : percent > 20
            ? const Color(0xFFFFA502)  // Samsung Orange
            : const Color(0xFFFF4757);  // Samsung Coral Red

    try {
      await HomeWidget.renderFlutterWidget(
        Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 86,
            height: 98,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 62,
                  height: 54,
                  child: CustomPaint(
                    painter: _SamsungHorseshoePainter(
                      progress: pct.clamp(0.0, 1.0),
                      activeColor: color,
                      trackColor: const Color(0xFF383D4A),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Icon(
                          icon,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$percent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF9EA6B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
        key: key,
        logicalSize: const Size(86, 98),
        pixelRatio: 3.0,
      );
    } catch (e) {
      debugPrint('Error renderizando arco $key: $e');
    }
  }

  /// Renderiza una barra horizontal tipo cápsula / píldora Samsung One UI
  static Future<void> _renderSamsungPillBar(
    String key, double pct, String label, IconData icon,
  ) async {
    final int percent = (pct * 100).round().clamp(0, 100);
    final Color color = percent > 50
        ? const Color(0xFF00E676)
        : percent > 20
            ? const Color(0xFFFFA502)
            : const Color(0xFFFF4757);

    try {
      await HomeWidget.renderFlutterWidget(
        Material(
          color: Colors.transparent,
          child: Container(
            width: 220,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Fondo de la cápsula
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C303B),
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                // Barra de progreso de color con bordes redondeados
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.08, 1.0),
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
                // Icono a la izquierda y porcentaje a la derecha
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$percent %',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        key: key,
        logicalSize: const Size(220, 40),
        pixelRatio: 3.0,
      );
    } catch (e) {
      debugPrint('Error renderizando píldora $key: $e');
    }
  }

  /// Registra el callback para acciones desde el widget.
  static Future<void> initializeWidgetInteraction() async {
    HomeWidget.setAppGroupId('group.my_auto_guide');
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'toggle_tracking') {
      final service = FlutterBackgroundService();
      bool running = await service.isRunning();
      
      if (running) {
        service.invoke('stopService');
      } else {
        await service.startService();
      }
    }
  }
}

/// CustomPainter para el arco en herradura con puntas redondeadas idéntico a Samsung One UI
class _SamsungHorseshoePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color trackColor;

  _SamsungHorseshoePainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final radius = min(size.width, size.height) / 2 - 4;
    const strokeWidth = 7.0;

    // Arco de 240° (desde 150° hasta 390°, apertura hacia abajo)
    const startAngle = 5 * pi / 6; // 150 grados
    const totalSweep = 4 * pi / 3; // 240 grados

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Dibujar fondo de la herradura
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // Dibujar arco de progreso activo
    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        totalSweep * progress,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SamsungHorseshoePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
