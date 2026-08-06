import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/vehicle_provider.dart';
import 'core/services/sync_service.dart';
import 'core/services/background_nav_service.dart';
import 'core/logic/app_widget_logic.dart';
import 'features/auth/login_screen.dart';
import 'core/logic/performance_guard.dart';
import 'core/utils/app_logger.dart';

/// Detecta si la app fue abierta desde un widget con deep link
Future<void> _checkWidgetLaunch() async {
  try {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null && uri.host == 'start_free_tracking') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('widget_start_tracking', true);
    }
  } catch (e, stackTrace) {
    AppLogger.error('main._checkWidgetLaunch', e, stackTrace);
  }

  // También escuchar clicks futuros mientras la app está abierta
  HomeWidget.widgetClicked.listen((uri) async {
    try {
      if (uri != null && uri.host == 'start_free_tracking') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('widget_start_tracking', true);
      }
    } catch (e, stackTrace) {
      AppLogger.error('main.widgetClicked', e, stackTrace);
    }
  }, onError: (Object e, StackTrace stackTrace) {
    AppLogger.error('main.widgetClicked', e, stackTrace);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar variables de entorno (dotenv). Es opcional: los valores pueden
  // venir de --dart-define, así que sólo se advierte si el archivo no existe.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e, stackTrace) {
    AppLogger.warning(
        'main.dotenv (archivo .env no encontrado)', e, stackTrace);
  }

  // 2. Inicializar Sentry antes del resto para poder reportar fallas de arranque
  final sentryDsn = dotenv.get('SENTRY_DSN', fallback: '');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 1.0;
    });
  } else {
    debugPrint('Sentry DSN no configurado. Saltando inicialización de Sentry.');
  }

  try {
    // 3. Inicializar Rendimiento (PerformanceGuard)
    if (!kIsWeb) {
      await PerformanceGuard().initialize();
    }

    // 4. Inicializar Supabase
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL',
          fallback: const String.fromEnvironment('SUPABASE_URL')),
      anonKey: dotenv.get('SUPABASE_ANON_KEY',
          fallback: const String.fromEnvironment('SUPABASE_ANON_KEY')),
    );

    // 5. Inicializar Firebase (Push Notifications). La app funciona sin push,
    // por lo que la falla se reporta pero no impide el arranque.
    try {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
    } catch (e, stackTrace) {
      AppLogger.error('main.firebase', e, stackTrace);
    }

    // 6. Inicializar Sync Service para sincronización offline
    SyncService().initialize();

    // 7. Inicializar Notificaciones y Zonas Horarias
    if (!kIsWeb) {
      await NotificationService().init();
      await BackgroundNavService.initializeService();
      await AppWidgetLogic.initializeWidgetInteraction();

      // Detectar si la app se abrió desde un widget
      unawaited(_checkWidgetLaunch());
    }

    // 8. Arrancar la app sólo cuando la inicialización terminó correctamente
    runApp(const MyApp());
  } catch (e, stackTrace) {
    AppLogger.error('main.initialize', e, stackTrace);
    runApp(_InitializationErrorApp(message: e.toString()));
  }
}

class _InitializationErrorApp extends StatelessWidget {
  const _InitializationErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No pudimos iniciar My Auto Guide',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB), // Azul moderno
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.outfitTextTheme(),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        ),
        themeMode: ThemeMode.system,
        home: const CarRentalLoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
