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
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // VULN-01
import '../../features/navigation/logic/gps_filter_service.dart';
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

    // Seguimiento GPS con filtro de Kalman cinemático
    double totalDistance = 0.0;
    LatLng? lastPos;
    final gpsFilter = GpsFilterService(
      maxAccuracyThreshold: 20.0,
      minMovingSpeedMs: 0.8,
      maxPlausibleSpeedMs: 55.0,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // =========================================================
      // 1. INICIAR GPS CON PRECISIÓN VIAL ÓPTIMA (CRÍTICO)
      // =========================================================
      late LocationSettings locationSettings;
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation, 
          distanceFilter: 3, // 3m para capturar maniobras fluidas
          forceLocationManager: false, // FusedLocationProvider es mucho más confiable
          intervalDuration: const Duration(milliseconds: 1500), 
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType: ActivityType.automotiveNavigation,
          distanceFilter: 3,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          allowBackgroundLocationUpdates: true,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        );
      }

      // Referencia a canal de Supabase si se logra conectar
      RealtimeChannel? supabaseChannel;
      
      // =========================================================
      // 2. INICIALIZAR SUPABASE DESDE ALMACENAMIENTO CIFRADO (VULN-01)
      // =========================================================
      Future(() async {
        try {
          // Leer credenciales desde Android Keystore / iOS Keychain (cifradas)
          const secureStorage = FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
              synchronizable: false,
            ),
          );
          final url = await secureStorage.read(key: 'secure_supabase_url') ?? '';
          final key = await secureStorage.read(key: 'secure_supabase_anon_key') ?? '';
          final vehicleId = prefs.getString('active_nav_vehicle_id') ?? 'unknown';

          if (url.isNotEmpty && key.isNotEmpty) {
            await Supabase.initialize(url: url, anonKey: key);
            final client = Supabase.instance.client;
            supabaseChannel = client.channel('tracking:$vehicleId');
            supabaseChannel?.subscribe();
          }
        } catch (e) {
          debugPrint('Error inicializando Supabase en Background (GPS continuará): $e');
        }
      });

      // =========================================================
      // 3. GESTIÓN DEL STREAM GPS CONTINUO CON FILTRADO KALMAN
      // =========================================================
      StreamSubscription<Position>? gpsSubscription;

      gpsSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) async {
        final filterResult = gpsFilter.filterPoint(
          lat: position.latitude,
          lng: position.longitude,
          accuracy: position.accuracy,
          speedMs: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
        );

        // Descartar lectura si fue rechazada por salto extremo o imprecisión > 20m
        if (filterResult == null) return;

        final currentPos = filterResult.position;

        if (lastPos != null && !filterResult.isStationary) {
          final distance = Geolocator.distanceBetween(
            lastPos!.latitude,
            lastPos!.longitude,
            currentPos.latitude,
            currentPos.longitude,
          );
          // Filtrar ruido: ignorar movimientos < 3.5m o saltos irreales > 250m
          if (distance >= 3.5 && distance <= 250.0) {
            totalDistance += distance;
            lastPos = currentPos;
          }
        } else if (lastPos == null) {
          lastPos = currentPos;
        }

        // PRIORIDAD 1: Actualizar la UI inmediatamente con datos filtrados
        service.invoke('update', {
          "lat": currentPos.latitude,
          "lng": currentPos.longitude,
          "rawLat": position.latitude,
          "rawLng": position.longitude,
          "distance": totalDistance / 1000,
          "speed": filterResult.speedMs, // En m/s
          "bearing": filterResult.bearing,
          "accuracy": position.accuracy,
          "isStationary": filterResult.isStationary,
        });

        // PRIORIDAD 2: Actualizar Notificación de Android
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            service.setForegroundNotificationInfo(
              title: notificationTitle,
              content: 'Recorrido: ${(totalDistance / 1000).toStringAsFixed(2)} km',
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
          prefs.setDouble('nav_last_lat', currentPos.latitude);
          prefs.setDouble('nav_last_lng', currentPos.longitude);

          // Transmisión asíncrona segura
          supabaseChannel?.track({
            'lat': currentPos.latitude,
            'lng': currentPos.longitude,
            'dist': totalDistance / 1000,
            'ts': DateTime.now().millisecondsSinceEpoch,
            'speed': filterResult.speedMs,
            'bearing': filterResult.bearing,
          });
        } catch (e) {
          debugPrint('Fallo secundario en background: $e');
        }
      }, onError: (e) {
        debugPrint('Error en stream GPS: $e');
        service.invoke('error', {
          "message": "Error GPS: $e. Verifica permisos y señal."
        });
      });
    } catch (e) {
      debugPrint('Error fatal iniciando background GPS: $e');
      service.invoke('error', {"message": "Crash total en background: $e"});
    }
  }
}

