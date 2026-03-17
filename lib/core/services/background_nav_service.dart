import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../logic/app_widget_logic.dart';

class BackgroundNavService {
  static const String channelId = 'my_auto_guide_nav';
  static const String notificationTitle = 'Recorrido en Progreso';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: channelId,
        initialNotificationTitle: notificationTitle,
        initialNotificationContent: 'Preparando seguimiento GPS...',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      AppWidgetLogic.updateWidget(distance: 0, isTracking: false);
      service.stopSelf();
    });

    // Seguimiento GPS
    double totalDistance = 0.0;
    LatLng? lastPos;

    final prefs = await SharedPreferences.getInstance();
    String? vehiculoId = prefs.getString('active_nav_vehicle_id');

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) async {
      final currentPos = LatLng(position.latitude, position.longitude);

      if (lastPos != null) {
        final distance = Geolocator.distanceBetween(lastPos!.latitude,
            lastPos!.longitude, currentPos.latitude, currentPos.longitude);
        totalDistance += distance;
      }
      lastPos = currentPos;

      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          service.setForegroundNotificationInfo(
            title: notificationTitle,
            content:
                'Distancia recorrida: ${(totalDistance / 1000).toStringAsFixed(2)} km',
          );
        }
      }

      // Enviar datos a la app (si está abierta)
      service.invoke('update', {
        "lat": position.latitude,
        "lng": position.longitude,
        "distance": totalDistance / 1000,
      });

      // Actualizar Widget de Inicio
      AppWidgetLogic.updateWidget(
        distance: totalDistance / 1000,
        isTracking: true,
      );

      // Guardar localmente para persistencia en caso de cierre total
      prefs.setDouble('nav_total_distance', totalDistance / 1000);
      prefs.setDouble('nav_last_lat', position.latitude);
      prefs.setDouble('nav_last_lng', position.longitude);
    });
  }
}
