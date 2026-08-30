import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_apple_theme.dart';
import 'core/services/notification_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/vehicle_provider.dart';
import 'core/services/sync_service.dart';
import 'core/services/background_nav_service.dart';
import 'core/logic/app_widget_logic.dart';
import 'features/auth/login_screen.dart';
import 'core/logic/performance_guard.dart';

/// Detecta si la app fue abierta desde un widget con deep link
void _checkWidgetLaunch() async {
  final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  if (uri != null && uri.host == 'start_free_tracking') {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widget_start_tracking', true);
  }
  
  // También escuchar clicks futuros mientras la app está abierta
  HomeWidget.widgetClicked.listen((uri) async {
    if (uri != null && uri.host == 'start_free_tracking') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('widget_start_tracking', true);
    }
  });
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
// 1. Cargar variables de entorno (dotenv)
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Archivo .env no encontrado. Asegúrate de crearlo.");
    }

    // 2. Inicializar Rendimiento (PerformanceGuard)
    if (!kIsWeb) {
      await PerformanceGuard().initialize();
    }

    // 2. Inicializar Supabase
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL',
          fallback: const String.fromEnvironment('SUPABASE_URL')),
      anonKey: dotenv.get('SUPABASE_ANON_KEY',
          fallback: const String.fromEnvironment('SUPABASE_ANON_KEY')),
    );

    // 3. Inicializar Firebase (Push Notifications)
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint("Advertencia: Firebase no se pudo inicializar (falta google-services.json): $e");
    }

    // 4. Inicializar Sync Service para sincronización offline
    SyncService().initialize();

    // 5. Inicializar Notificaciones y Zonas Horarias
    if (!kIsWeb) {
      await NotificationService().init();
      await BackgroundNavService.initializeService();
      await AppWidgetLogic.initializeWidgetInteraction();
      
      // Detener servicio en segundo plano si quedó activo sin navegación en curso para no dejar la notificación fija
      try {
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          final prefs = await SharedPreferences.getInstance();
          final isNavigating = prefs.getBool('is_navigating') ?? false;
          if (!isNavigating) {
            service.invoke('stopService');
          }
        }
      } catch (_) {}

      // Detectar si la app se abrió desde un widget
      _checkWidgetLaunch();
    }

    // 6. Inicializar Sentry y arrancar la app
    final sentryDsn = dotenv.get('SENTRY_DSN', fallback: '');
    if (sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 0.1; // Solo 10% de transacciones (SEGURIDAD)
          options.sampleRate = 0.5;       // Solo 50% de errores
          // Filtrar datos PII antes de enviar a servidores externos
          options.beforeSend = (event, hint) {
            return event.copyWith(
              extra: Map.fromEntries(
                (event.extra ?? {}).entries.where(
                  (e) => !['lat', 'lng', 'latitude', 'longitude', 'cedula', 'supabase_key'].contains(e.key),
                ),
              ),
            );
          };
        },
        appRunner: () => runApp(const MyApp()),
      );
    } else {
      debugPrint(
          'Sentry DSN no configurado. Saltando inicialización de Sentry.');
      runApp(const MyApp());
    }
  } catch (e, stackTrace) {
    // En caso de error en inicialización, mostrar pantalla de error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error al inicializar la app: $e'),
        ),
      ),
    ));
    // Reportar a Sentry si está disponible
    Sentry.captureException(e, stackTrace: stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
      ],
      child: MaterialApp(
        title: 'My Auto Guide',
        theme: AppAppleTheme.lightTheme,
        darkTheme: AppAppleTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const CarRentalLoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
