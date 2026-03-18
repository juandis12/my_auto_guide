import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      
      // =========================================================
      // 1. INICIAR GPS INMEDIATAMENTE (CRÍTICO)
      // =========================================================
      late LocationSettings locationSettings;
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high, 
          distanceFilter: 5, // 5m es óptimo para balancear precisión y eventos
          forceLocationManager: false, // FusedLocationProvider es mucho más confiable
          intervalDuration: const Duration(seconds: 2), 
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 5,
          pauseLocationUpdatesAutomatically: false,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        );
      }

      // Referencia a canal de Supabase si se logra conectar
      RealtimeChannel? supabaseChannel;
      
      // =========================================================
      // 2. INICIALIZAR SUPABASE ASÍNCRONAMENTE (NO BLOQUEANTE)
      // =========================================================
      Future(() async {
        try {
          final url = prefs.getString('supabase_url') ?? '';
          final key = prefs.getString('supabase_key') ?? '';
          final vehicleId = prefs.getString('active_nav_vehicle_id') ?? 'unknown';

          if (url.isNotEmpty && key.isNotEmpty) {
            await Supabase.initialize(url: url, anonKey: key);
            final client = Supabase.instance.client;
            supabaseChannel = client.channel('tracking:$vehicleId');
            supabaseChannel?.subscribe(); 
          }
        } catch (e) {
          debugPrint('Error inicializando Supabase en Background (GPS continuará operando): $e');
        }
      });

      // =========================================================
      // 3. GESTIÓN DEL STREAM GPS (ADAPTATIVO - MODO BATERÍA)
      // =========================================================
      StreamSubscription<Position>? gpsSubscription;
      int currentInterval = 5; // Default 5s
      DateTime lastConfigChange = DateTime.now();

      void startGpsStream(int interval) {
        gpsSubscription?.cancel();
        currentInterval = interval;
        lastConfigChange = DateTime.now();

        final newSettings = defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5,
                intervalDuration: Duration(seconds: interval),
              )
            : locationSettings; // iOS/Other settings are more static or managed by OS

        gpsSubscription = Geolocator.getPositionStream(
          locationSettings: newSettings,
        ).listen((Position position) async {
          final currentPos = LatLng(position.latitude, position.longitude);

          if (lastPos != null) {
            final distance = Geolocator.distanceBetween(lastPos!.latitude,
                lastPos!.longitude, currentPos.latitude, currentPos.longitude);
            totalDistance += distance;
          }
          lastPos = currentPos;

          // PRIORIDAD 1: Actualizar la UI inmediatamente
          service.invoke('update', {
            "lat": position.latitude,
            "lng": position.longitude,
            "distance": totalDistance / 1000,
            "speed": position.speed, // En m/s
          });

          // PRIORIDAD 2: Actualizar Notificación de Android
          if (service is AndroidServiceInstance) {
            if (await service.isForegroundService()) {
              service.setForegroundNotificationInfo(
                title: notificationTitle,
                content: 'Recorrido: ${(totalDistance / 1000).toStringAsFixed(2)} km - ${interval}s scan',
              );
            }
          }

          // PRIORIDAD 3: Persistencia y Red
          try {
            AppWidgetLogic.updateWidget(
              distance: totalDistance / 1000,
              isTracking: true,
            );

            prefs.setDouble('nav_total_distance', totalDistance / 1000);
            prefs.setDouble('nav_last_lat', position.latitude);
            prefs.setDouble('nav_last_lng', position.longitude);

            // Transmisión asíncrona segura
            supabaseChannel?.track({
              'lat': position.latitude,
              'lng': position.longitude,
              'dist': totalDistance / 1000,
              'ts': DateTime.now().millisecondsSinceEpoch,
              'speed': position.speed,
              'interval': interval,
            });
          } catch (e) {
            debugPrint('Fallo secundario en background: $e');
          }

          // =========================================================
          // 4. LÓGICA DE ADAPTACIÓN (EXTREMA BATERÍA)
          // =========================================================
          final speedKmH = position.speed * 3.6;
          final timeSinceChange = DateTime.now().difference(lastConfigChange).inSeconds;

          if (timeSinceChange > 20) { // Histéresis de 20 segundos
            int nextInterval = 5;
            if (speedKmH < 5) {
              nextInterval = 10; // Trancón / Detenerse
            } else if (speedKmH > 60) {
              nextInterval = 2; // Alta velocidad, curvas cerradas
            }

            if (nextInterval != currentInterval) {
              debugPrint('Adaptive GPS: Changing interval from $currentInterval to $nextInterval (Speed: ${speedKmH.toStringAsFixed(1)} km/h)');
              startGpsStream(nextInterval);
            }
          }
        }, onError: (e) {
          debugPrint('Error en stream GPS: $e');
          service.invoke('error', {
            "message": "Error GPS: $e. Verifica permisos y señal."
          });
        });
      }

      // Iniciar con el intervalo inicial
      startGpsStream(5);
    } catch (e) {
      debugPrint('Error fatal iniciando background GPS: $e');
      service.invoke('error', {"message": "Crash total en background: $e"});
    }
  }
}

