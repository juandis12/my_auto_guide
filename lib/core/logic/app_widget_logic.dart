import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class AppWidgetLogic {
  static const String androidWidgetName = 'AppWidgetProvider';
  static const String healthWidgetName = 'VehicleStatusWidgetProvider';
  
  /// Actualiza los datos visibles en el widget de navegación.
  static Future<void> updateWidget({
    required double distance,
    required bool isTracking,
  }) async {
    await HomeWidget.saveWidgetData<double>('current_distance', distance);
    await HomeWidget.saveWidgetData<bool>('is_tracking', isTracking);
    
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
    );
  }

  /// Actualiza los datos del widget de salud con indicadores circulares.
  /// Renderiza cada indicador como imagen PNG para el widget nativo.
  static Future<void> updateHealthWidget({
    required double pctCadena,
    required double pctFiltro,
    required double pctAceite,
    required double pctSoat,
    required double pctTecno,
  }) async {
    // Renderizar cada indicador circular como imagen
    await _renderCircularIndicator('widget_cadena', pctCadena, 'Cadena');
    await _renderCircularIndicator('widget_filtro', pctFiltro, 'Filtro');
    await _renderCircularIndicator('widget_aceite', pctAceite, 'Aceite');
    await _renderCircularIndicator('widget_soat', pctSoat, 'SOAT');
    await _renderCircularIndicator('widget_tecno', pctTecno, 'Tecno');
    
    await HomeWidget.updateWidget(
      androidName: healthWidgetName,
    );
  }

  /// Renderiza un indicador circular con porcentaje como imagen PNG.
  static Future<void> _renderCircularIndicator(
    String key, double pct, String label,
  ) async {
    final int percent = (pct * 100).round().clamp(0, 100);
    final Color color = percent > 50
        ? const Color(0xFF4CAF50)  // Verde
        : percent > 20
            ? const Color(0xFFFF9800)  // Naranja
            : const Color(0xFFF44336);  // Rojo

    try {
      await HomeWidget.renderFlutterWidget(
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fondo del círculo
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withOpacity(0.2),
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
              // Progreso real
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  backgroundColor: Colors.transparent,
                ),
              ),
              // Texto del porcentaje
              Text(
                '$percent%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: percent == 100 ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        key: key,
        logicalSize: const Size(56, 56),
        pixelRatio: 3.0,
      );
    } catch (e) {
      debugPrint('Error renderizando indicador $key: $e');
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
