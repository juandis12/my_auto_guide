import 'package:home_widget/home_widget.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

class AppWidgetLogic {
  static const String androidWidgetName = 'AppWidgetProvider';
  
  /// Actualiza los datos visibles en el widget (distancia y estado).
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

  /// Registra el callback para acciones desde el widget (Play/Stop).
  static Future<void> initializeWidgetInteraction() async {
    HomeWidget.setAppGroupId('group.my_auto_guide');
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'toggle_tracking') {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('stopService');
      } else {
        await service.startService();
      }
    }
  }
}
