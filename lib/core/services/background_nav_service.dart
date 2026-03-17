import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../logic/app_widget_logic.dart';

class BackgroundNavService {
  static const String channelId = 'my_auto_guide_nav';
  static const String notificationTitle = 'Recorrido en Progreso';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Pequeño delay para asegurar que otros servicios (notificaciones) estén listos
    await Future.delayed(const Duration(milliseconds: 500));

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
    WidgetsFlutterBinding.ensureInitialized();
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

    try {
      final prefs = await SharedPreferences.getInstance();
      
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // Reducido: Más sensible al movimiento para evitar sensación de congelamiento
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
                  'Recorrido: ${(totalDistance / 1000).toStringAsFixed(2)} km - Seguimiento activo',
            );
          }
        }

        // Actualizar datos en tiempo real
        service.invoke('update', {
          "lat": position.latitude,
          "lng": position.longitude,
          "distance": totalDistance / 1000,
        });

        // Actualizar Widget
        await AppWidgetLogic.updateWidget(
          distance: totalDistance / 1000,
          isTracking: true,
        );

        // Persistencia
        await prefs.setDouble('nav_total_distance', totalDistance / 1000);
        await prefs.setDouble('nav_last_lat', position.latitude);
        await prefs.setDouble('nav_last_lng', position.longitude);
      }, onError: (e) {
        debugPrint('Error en stream GPS: $e');
      });
    } catch (e) {
      debugPrint('Error fatal en servicio de fondo: $e');
    }
  }
}
